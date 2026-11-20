package core

import (
	"path/filepath"
	"testing"
	"time"

	C "github.com/metacubex/mihomo/constant"
)

func testHistory(t *testing.T) (*trafficHistory, string) {
	t.Helper()
	path := filepath.Join(t.TempDir(), "history.db")
	history := &trafficHistory{}
	if err := history.open(path); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = history.db.Close() })
	return history, path
}

func historyTotals(t *testing.T, history *trafficHistory) (upload, download, runtime int64) {
	t.Helper()
	answer, err := history.read(0)
	if err != nil {
		t.Fatal(err)
	}
	for _, row := range answer.Rows {
		upload += row.Upload
		download += row.Download
		runtime += row.Runtime
	}
	return
}

func TestTrafficHistoryRecordsWithoutFlutterAndReopens(t *testing.T) {
	history, path := testHistory(t)
	now := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	history.last = now
	tracker := newPipeTracker(t)
	tracker.Info().UploadTotal.Store(20)
	tracker.Info().DownloadTotal.Store(100)
	history.watch(tracker, &C.Metadata{Process: "com.facebook.katana", Host: "example.com", NetWork: C.TCP})
	if err := history.sample(now.Add(time.Second)); err != nil {
		t.Fatal(err)
	}
	if err := history.sample(now.Add(2 * time.Second)); err != nil {
		t.Fatal(err)
	}
	up, down, duration := historyTotals(t, history)
	if up != 20 || down != 100 || duration != 2000 {
		t.Fatalf("totals = %d/%d/%d", up, down, duration)
	}
	answer, _ := history.read(0)
	empty, err := history.read(answer.Revision)
	if err != nil || len(empty.Rows) != 0 {
		t.Fatalf("unchanged history = %+v, %v", empty, err)
	}
	if err := history.db.Close(); err != nil {
		t.Fatal(err)
	}
	history.db = nil
	if err := history.open(path); err != nil {
		t.Fatal(err)
	}
	up, down, duration = historyTotals(t, history)
	if up != 20 || down != 100 || duration != 2000 {
		t.Fatal("reopen lost committed history")
	}
	if !history.last.IsZero() {
		t.Fatal("reopening counted process downtime as VPN runtime")
	}
}

func TestTrafficHistorySplitsMidnightAndCountsOnlySessionTime(t *testing.T) {
	history, _ := testHistory(t)
	start := time.Date(2026, 11, 20, 23, 59, 59, 0, time.UTC)
	history.last = start
	tracker := newPipeTracker(t)
	history.watch(tracker, &C.Metadata{Host: "example.com", NetWork: C.TCP})
	tracker.Info().DownloadTotal.Store(100)
	if err := history.sample(start.Add(500 * time.Millisecond)); err != nil {
		t.Fatal(err)
	}
	tracker.Info().DownloadTotal.Store(150)
	if err := history.sample(start.Add(2 * time.Second)); err != nil {
		t.Fatal(err)
	}
	answer, err := history.read(0)
	if err != nil {
		t.Fatal(err)
	}
	var firstDown, secondDown, firstDuration, secondDuration int64
	for _, row := range answer.Rows {
		if row.Hour == hourStart(start).UnixMilli() {
			firstDown += row.Download
			firstDuration += row.Runtime
		} else {
			secondDown += row.Download
			secondDuration += row.Runtime
		}
	}
	if firstDown != 100 || secondDown != 50 || firstDuration != 1000 || secondDuration != 1000 {
		t.Fatalf("midnight buckets: %d/%d bytes, %d/%d ms", firstDown, secondDown, firstDuration, secondDuration)
	}
	history.stop(start.Add(3 * time.Second))
	_, _, before := historyTotals(t, history)
	if err := history.sample(start.Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	_, _, after := historyTotals(t, history)
	if before != after {
		t.Fatal("stopped VPN accumulated runtime")
	}
	history.last = start.Add(time.Hour)
	if err := history.sample(start.Add(time.Hour + time.Second)); err != nil {
		t.Fatal(err)
	}
	_, _, resumed := historyTotals(t, history)
	if resumed != after+1000 {
		t.Fatal("a new VPN session counted the disconnected gap")
	}
}

func TestTrafficHistoryDoesNotAdvanceCheckpointOnFailedCommit(t *testing.T) {
	history, path := testHistory(t)
	start := time.Now()
	history.last = start
	tracker := newPipeTracker(t)
	history.watch(tracker, &C.Metadata{NetWork: C.TCP})
	tracker.Info().DownloadTotal.Store(100)
	if err := history.db.Close(); err != nil {
		t.Fatal(err)
	}
	if err := history.sample(start.Add(time.Second)); err == nil {
		t.Fatal("closed database accepted a commit")
	}
	if history.connections[tracker.ID()].download != 0 || !history.last.Equal(start) {
		t.Fatal("failed commit advanced checkpoint")
	}
	reopened := &trafficHistory{}
	if err := reopened.open(path); err != nil {
		t.Fatal(err)
	}
	history.db = reopened.db
	if err := history.sample(start.Add(2 * time.Second)); err != nil {
		t.Fatal(err)
	}
	_, down, runtime := historyTotals(t, history)
	if down != 100 || runtime != 2000 {
		t.Fatalf("retry lost data: %d/%d", down, runtime)
	}
}

func TestTrafficHistoryUsesDeviceTimezoneAndKeepsSubsecondRuntime(t *testing.T) {
	history, _ := testHistory(t)
	location, err := time.LoadLocation("Asia/Kathmandu")
	if err != nil {
		t.Fatal(err)
	}
	history.location = location
	start := time.Date(2026, 11, 20, 23, 59, 59, 123456789, location)
	history.last = start.UTC()
	for i := 1; i <= 2000; i++ {
		if err := history.sample(start.Add(time.Duration(i) * 750 * time.Microsecond).UTC()); err != nil {
			t.Fatal(err)
		}
	}
	answer, err := history.read(0)
	if err != nil {
		t.Fatal(err)
	}
	var duration int64
	for _, row := range answer.Rows {
		local := time.UnixMilli(row.Hour).In(location)
		if local.Minute() != 0 {
			t.Fatalf("bucket is not on device hour: %s", local)
		}
		duration += row.Runtime
	}
	if duration != 1500 {
		t.Fatalf("runtime lost fractional samples: %d", duration)
	}
}
