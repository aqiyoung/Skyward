package core

import (
	"github.com/metacubex/mihomo/component/process"
	"github.com/metacubex/mihomo/component/resolver"
	"github.com/metacubex/mihomo/component/tun"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/dns"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

type requestSnapshot struct {
	*statistic.TrackerInfo
	Metadata *constant.Metadata `json:"metadata"`
}

func snapshotRequest(info *statistic.TrackerInfo, lookup process.PackageNameResolver) *requestSnapshot {
	metadata := info.Metadata
	if lookup != nil && metadata != nil && metadata.Type != constant.INNER && metadata.Process == "" {
		// Find-process-mode can be off; attribute statistics without changing routing metadata.
		resolved := *metadata
		if name, err := lookup(&resolved); err == nil && name != "" {
			resolved.Process = name
			metadata = &resolved
		}
	}
	return &requestSnapshot{TrackerInfo: info, Metadata: metadata}
}

func handleGetTraffic(onlyStatisticsProxy bool) Traffic {
	up, down := statistic.DefaultManager.NowTraffic(onlyStatisticsProxy)
	return Traffic{Up: up, Down: down}
}

func handleGetTotalTraffic(onlyStatisticsProxy bool) Traffic {
	up, down := statistic.DefaultManager.TotalTraffic(onlyStatisticsProxy)
	return Traffic{Up: up, Down: down}
}

func handleResetTraffic() {
	statistic.DefaultManager.ResetStatistic()
}

func handleGetConnections() []*requestSnapshot {
	// The live-connections page used to get the raw tracker snapshot, which
	// never carries the app name -- only the RequestMessage event did. Give
	// every connection the same process-attributed snapshot so the list and
	// the request history show the same logo.
	connections := make([]*requestSnapshot, 0)
	statistic.DefaultManager.Range(func(track statistic.Tracker) bool {
		connections = append(connections, snapshotRequest(track.Info(), tun.FindPackageName))
		return true
	})
	return connections
}

func handleGetConnectionCount() int {
	count := 0
	statistic.DefaultManager.Range(func(statistic.Tracker) bool {
		count++
		return true
	})
	return count
}

func handleCloseConnections() bool {
	statistic.DefaultManager.Range(func(c statistic.Tracker) bool {
		_ = c.Close()
		return true
	})
	return true
}

func handleResetConnections() bool {
	resolver.ResetConnection()
	return true
}

// A network change clears rather than waits out the TTLs: mihomo serves an
// expired entry once more before it refreshes it.
func handleClearDnsCache() {
	configMu.Lock()
	defer configMu.Unlock()
	dns.ClearAll()
}

// A connection that went out over a network the device has left hangs until
// TCP gives up on it, and so do the DNS clients' pooled connections.
func handleResetNetwork() {
	handleCloseConnections()
	handleClearDnsCache()
}

func handleCloseConnection(connectionId string) bool {
	c := statistic.DefaultManager.Get(connectionId)
	if c == nil {
		return false
	}
	_ = c.Close()
	return true
}
