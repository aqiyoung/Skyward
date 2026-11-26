package core

import (
	"core/tun"
	"runtime"
	"sync"
	"time"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/component/proxydialer"
	"github.com/metacubex/mihomo/component/updater"
	"github.com/metacubex/mihomo/dns"
	"github.com/metacubex/mihomo/hub/executor"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

func init() {
	adapter.UrlTestHook = func(url string, name string, delay uint16, timedOut bool) {
		sendMessage(DelayMessage, &Delay{Url: url, Name: name, Value: delayValue(delay, timedOut)})
		// Feed RCX's delay learning from the same URL test the app shows. Its
		// own probes are excluded so they are not counted twice.
		if e := rcxIfReady(); e != nil && url == currentTestURL() && !rcxOwnProbes.owns(name) {
			e.NoteURLTest(name, int(delay))
		}
	}
	// This fork's mihomo has no DialResultHook or DefaultFirstProgressNotify,
	// so RCX does not get dial-failure and traffic signals here. Its delay
	// learning still works through UrlTestHook below; the engine treats the
	// missing signals as simply unobserved.
	statistic.DefaultRequestNotify = func(c statistic.Tracker) {
		notifyProbeRoute(c)
		if runtime.GOOS == "android" {
			snapshot := snapshotRequest(c.Info(), tun.FindPackageName)
			nativeHistory.watch(c, snapshot.Metadata)
			if hasEventListener() {
				sendMessage(RequestMessage, snapshot)
				watchRequestTraffic(c)
			}
			return
		}
		if hasEventListener() {
			sendMessage(RequestMessage, c)
			watchRequestTraffic(c)
		}
	}
	dns.DefaultQueryNotify = func(record dns.QueryRecord) {
		if hasEventListener() {
			sendMessage(DnsMessage, newDnsQuery(record))
		}
	}
	executor.DefaultProviderLoadedHook = func(providerName string) {
		requestRcxTopologyRefresh()
		scheduleReclaimOwnership()
		scheduleLoadMemoryRelease()
		sendMessage(LoadedMessage, providerName)
	}
	updater.GeoUpdateHook = onGeoUpdate
	proxydialer.DefaultLoopNotify = reportDialerLoop
}

// Every dial through a looping dialer fails; one report stands for the burst.
const dialerLoopReportInterval = 3 * time.Second

var dialerLoopReports sync.Map

func reportDialerLoop(proxyName string) {
	now := time.Now()
	if last, ok := dialerLoopReports.Load(proxyName); ok && now.Sub(last.(time.Time)) < dialerLoopReportInterval {
		return
	}
	dialerLoopReports.Store(proxyName, now)
	sendMessage(DialerLoopMessage, proxyName)
}
