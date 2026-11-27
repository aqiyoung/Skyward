package core

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"path/filepath"
	"sync"
	"time"
	_ "time/tzdata"

	bolt "github.com/metacubex/bbolt"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

type historyRow struct {
	ID          string `json:"id"`
	Hour        int64  `json:"hour"`
	Host        string `json:"host"`
	Rule        string `json:"rule"`
	RulePayload string `json:"rulePayload"`
	Node        string `json:"node"`
	Network     string `json:"network"`
	Process     string `json:"process"`
	Upload      int64  `json:"upload"`
	Download    int64  `json:"download"`
	Runtime     int64  `json:"runtime"`
	Connections int64  `json:"connections"`
	Revision    uint64 `json:"revision"`
}

type historyAnswer struct {
	Rows     []historyRow `json:"rows"`
	Revision uint64       `json:"revision"`
}

type historyConnection struct {
	tracker          statistic.Tracker
	metadata         historyRow
	upload, download int64
	fresh            bool
	counted          bool
}

type trafficHistory struct {
	mu          sync.Mutex
	db          *bolt.DB
	connections map[string]*historyConnection
	last        time.Time
	done        chan struct{}
	location    *time.Location
	prunedDay   time.Time
}

var nativeHistory = &trafficHistory{}
var historyBucket = []byte("hourly-v1")

func (h *trafficHistory) open(path string) error {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.db != nil {
		return nil
	}
	db, err := bolt.Open(path, 0600, &bolt.Options{Timeout: time.Second})
	if err != nil {
		return err
	}
	if err = db.Update(func(tx *bolt.Tx) error { _, err := tx.CreateBucketIfNotExists(historyBucket); return err }); err != nil {
		_ = db.Close()
		return err
	}
	h.db = db
	h.connections = make(map[string]*historyConnection)
	h.last = time.Time{}
	return nil
}

func (h *trafficHistory) start(now time.Time) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.db == nil || h.done != nil {
		return
	}
	h.last = now
	h.done = make(chan struct{})
	done := h.done
	safeGo("traffic history", func() {
		ticker := time.NewTicker(time.Second)
		defer ticker.Stop()
		for {
			select {
			case now := <-ticker.C:
				if err := h.sample(now); err != nil {
					logError("traffic history: %v", err)
				}
			case <-done:
				return
			}
		}
	})
}

func (h *trafficHistory) stop(now time.Time) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if err := h.sampleLocked(now); err != nil {
		logError("traffic history final flush: %v", err)
	}
	if h.done != nil {
		close(h.done)
		h.done = nil
	}
	h.last = time.Time{}
}

func (h *trafficHistory) watch(tracker statistic.Tracker, metadata *C.Metadata) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.db == nil || h.last.IsZero() || metadata == nil {
		return
	}
	info := tracker.Info()
	node := ""
	if len(info.Chain) > 0 {
		node = info.Chain[len(info.Chain)-1]
	}
	h.connections[tracker.ID()] = &historyConnection{tracker: tracker, fresh: true,
		metadata: historyRow{Host: metadata.Host, Rule: info.Rule, RulePayload: info.RulePayload,
			Node: node, Network: metadata.NetWork.String(), Process: metadata.Process},
	}
}

func hourStart(now time.Time) time.Time {
	return time.Date(now.Year(), now.Month(), now.Day(), now.Hour(), 0, 0, 0, now.Location())
}

func historyKey(row historyRow) string {
	encoded, _ := json.Marshal([]any{row.Hour, row.Host, row.Rule, row.RulePayload, row.Node, row.Network, row.Process})
	hash := sha256.Sum256(encoded)
	return hex.EncodeToString(hash[:])
}

func (h *trafficHistory) sample(now time.Time) error {
	h.mu.Lock()
	defer h.mu.Unlock()
	return h.sampleLocked(now)
}

func (h *trafficHistory) sampleLocked(now time.Time) error {
	if h.location != nil {
		now = now.In(h.location)
	}
	if h.db == nil || h.last.IsZero() {
		return nil
	}
	if !now.After(h.last) {
		return nil
	}
	deltas := make(map[string]historyRow)
	totals := make(map[string][2]int64)
	for id, connection := range h.connections {
		info := connection.tracker.Info()
		upload, download := max(connection.upload, info.UploadTotal.Load()), max(connection.download, info.DownloadTotal.Load())
		totals[id] = [2]int64{upload, download}
		row := connection.metadata
		row.Hour = hourStart(now).UnixMilli()
		row.ID = historyKey(row)
		row.Upload = upload - connection.upload
		row.Download = download - connection.download
		if !connection.counted {
			row.Connections = 1
		}
		previous := deltas[row.ID]
		row.Upload += previous.Upload
		row.Download += previous.Download
		row.Connections += previous.Connections
		deltas[row.ID] = row
	}
	for start := h.last.In(now.Location()); start.Before(now); {
		hour := hourStart(start)
		end := hour.Add(time.Hour)
		if end.After(now) {
			end = now
		}
		id := fmt.Sprintf("runtime/%d", hour.UnixMilli())
		deltas[id] = historyRow{ID: id, Hour: hour.UnixMilli(), Runtime: end.UnixMilli() - start.UnixMilli()}
		start = end
	}
	err := h.db.Update(func(tx *bolt.Tx) error {
		bucket := tx.Bucket(historyBucket)
		for id, delta := range deltas {
			if delta.Upload == 0 && delta.Download == 0 && delta.Runtime == 0 && delta.Connections == 0 {
				continue
			}
			var previous historyRow
			if data := bucket.Get([]byte(id)); data != nil {
				if err := json.Unmarshal(data, &previous); err != nil {
					// One corrupt row must not poison every later sample. Start
					// this connection from a clean baseline and overwrite it.
					logError("traffic history: dropping corrupt row %q: %v", id, err)
					previous = historyRow{}
				}
			}
			delta.Upload += previous.Upload
			delta.Download += previous.Download
			delta.Runtime += previous.Runtime
			delta.Connections += previous.Connections
			var err error
			delta.Revision, err = bucket.NextSequence()
			if err != nil {
				return err
			}
			data, err := json.Marshal(delta)
			if err != nil {
				return err
			}
			if err = bucket.Put([]byte(id), data); err != nil {
				return err
			}
		}
		if h.prunedDay.Year() == now.Year() && h.prunedDay.YearDay() == now.YearDay() {
			return nil
		}
		cutoff := now.AddDate(0, 0, -90).UnixMilli()
		cursor := bucket.Cursor()
		for key, data := cursor.First(); key != nil; key, data = cursor.Next() {
			var row historyRow
			if err := json.Unmarshal(data, &row); err != nil {
				// A row we cannot read is not worth keeping; drop it so pruning
				// cannot be wedged forever by a single bad record.
				logError("traffic history: pruning corrupt row: %v", err)
				if err := cursor.Delete(); err != nil {
					return err
				}
				continue
			}
			if row.Hour < cutoff {
				if err := cursor.Delete(); err != nil {
					return err
				}
			}
		}
		return nil
	})
	if err != nil {
		return err
	}
	for id, connection := range h.connections {
		connection.upload, connection.download = totals[id][0], totals[id][1]
		connection.counted = true
		if !connection.fresh && statistic.DefaultManager.Get(id) == nil {
			delete(h.connections, id)
		}
		connection.fresh = false
	}
	h.last = now
	h.prunedDay = now
	return nil
}

func (h *trafficHistory) read(since uint64) (historyAnswer, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	answer := historyAnswer{Rows: []historyRow{}}
	if h.db == nil {
		return answer, nil
	}
	err := h.db.View(func(tx *bolt.Tx) error {
		bucket := tx.Bucket(historyBucket)
		answer.Revision = bucket.Sequence()
		return bucket.ForEach(func(_, data []byte) error {
			var row historyRow
			if err := json.Unmarshal(data, &row); err != nil {
				// One corrupt row must not hide all history from the host.
				// Skip it; sampleLocked already rebuilds it on the next tick.
				logError("traffic history: skipping corrupt row on read: %v", err)
				return nil
			}
			if row.Revision > since {
				answer.Rows = append(answer.Rows, row)
			}
			return nil
		})
	})
	return answer, err
}

func handleGetTrafficHistory(since uint64) (historyAnswer, error) { return nativeHistory.read(since) }

func openNativeHistory(zone string) {
	location, err := time.LoadLocation(zone)
	if zone != "" && err == nil {
		nativeHistory.mu.Lock()
		nativeHistory.location = location
		nativeHistory.mu.Unlock()
	}
	if err := nativeHistory.open(filepath.Join(C.Path.HomeDir(), "traffic-history.db")); err != nil {
		logError("open traffic history: %v", err)
	}
}
