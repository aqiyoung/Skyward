package core

import (
	"encoding/json"
	"errors"
	"io"
	"net"
	"reflect"
	"testing"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

func TestRequestSnapshotResolvesAppWithoutChangingRoutingMetadata(t *testing.T) {
	for _, network := range []constant.NetWork{constant.TCP, constant.UDP} {
		t.Run(network.String(), func(t *testing.T) {
			source := &net.TCPAddr{IP: net.IPv4(10, 0, 0, 2), Port: 1234}
			target := &net.TCPAddr{IP: net.IPv4(1, 1, 1, 1), Port: 443}
			metadata := &constant.Metadata{
				Type: constant.TUN, NetWork: network,
				RawSrcAddr: source, RawDstAddr: target,
			}
			info := &statistic.TrackerInfo{Metadata: metadata, Chain: constant.Chain{"DIRECT"}}
			info.UploadTotal.Store(123)
			info.DownloadTotal.Store(456)
			snapshot := snapshotRequest(info, func(resolved *constant.Metadata) (string, error) {
				if resolved.RawSrcAddr != source || resolved.RawDstAddr != target {
					t.Fatal("package lookup lost the original socket addresses")
				}
				resolved.Uid = 10123
				return "com.facebook.katana", nil
			})
			if metadata.Process != "" || metadata.Uid != 0 {
				t.Fatal("statistics changed the metadata used by routing")
			}
			if snapshot.Metadata.Process != "com.facebook.katana" || snapshot.Metadata.Uid != 10123 {
				t.Fatalf("snapshot did not include the resolved app: %+v", snapshot.Metadata)
			}
			encoded, err := json.Marshal(snapshot)
			if err != nil {
				t.Fatal(err)
			}
			var decoded map[string]any
			if err := json.Unmarshal(encoded, &decoded); err != nil {
				t.Fatal(err)
			}
			if decoded["metadata"].(map[string]any)["process"] != "com.facebook.katana" ||
				decoded["upload"] != float64(123) || decoded["download"] != float64(456) ||
				!reflect.DeepEqual(decoded["chains"], []any{"DIRECT"}) {
				t.Fatalf("request event lost app or traffic fields: %s", encoded)
			}
		})
	}
}

func TestRequestSnapshotPreservesKnownAndUnresolvedMetadata(t *testing.T) {
	for _, test := range []struct {
		name     string
		metadata *constant.Metadata
		result   string
		err      error
		calls    int
	}{
		{name: "known package", metadata: &constant.Metadata{Process: "com.twitter.android"}},
		{name: "internal core traffic", metadata: &constant.Metadata{Type: constant.INNER}},
		{name: "missing metadata"},
		{name: "lookup failed", metadata: &constant.Metadata{}, err: errors.New("no owner"), calls: 1},
		{name: "owner unavailable", metadata: &constant.Metadata{}, calls: 1},
	} {
		t.Run(test.name, func(t *testing.T) {
			calls := 0
			info := &statistic.TrackerInfo{Metadata: test.metadata}
			snapshot := snapshotRequest(info, func(metadata *constant.Metadata) (string, error) {
				calls++
				metadata.Uid = 10123
				return test.result, test.err
			})
			if calls != test.calls || snapshot.Metadata != test.metadata {
				t.Fatalf("unnecessary lookup or metadata replacement: calls=%d", calls)
			}
			if test.metadata != nil && test.metadata.Uid != 0 {
				t.Fatal("failed lookup changed routing metadata")
			}
		})
	}
}

func TestProxyOnlyTrafficLeavesOutADirectProxyOfAnyName(t *testing.T) {
	direct := outbound.NewDirectWithOption(outbound.DirectOption{Name: "直连"})
	reject := outbound.NewRejectWithOption(outbound.RejectOption{Name: "HK"})
	tunnel.UpdateProxies(map[string]constant.Proxy{
		"直连": adapter.NewProxy(direct),
		"HK": adapter.NewProxy(reject),
	}, nil)
	t.Cleanup(func() { tunnel.UpdateProxies(nil, nil) })

	for _, test := range []struct {
		outbound constant.ProxyAdapter
		proxied  int64
	}{
		{direct, 0},
		{reject, 5},
	} {
		statistic.DefaultManager.ResetStatistic()
		local, remote := net.Pipe()
		go func() { _, _ = io.Copy(io.Discard, remote) }()
		tracker := statistic.NewTCPTracker(
			outbound.NewConn(local, test.outbound),
			statistic.DefaultManager,
			&constant.Metadata{},
			nil,
			0,
			0,
			true,
		)

		if _, err := tracker.Write([]byte("hello")); err != nil {
			t.Fatalf("write through %s: %v", test.outbound.Name(), err)
		}
		_ = tracker.Close()
		_ = remote.Close()

		all, _ := statistic.DefaultManager.TotalTraffic(false)
		proxied, _ := statistic.DefaultManager.TotalTraffic(true)
		if all != 5 || proxied != test.proxied {
			t.Errorf("%s: total %d, proxied %d; want 5 and %d", test.outbound.Name(), all, proxied, test.proxied)
		}
	}
	statistic.DefaultManager.ResetStatistic()
}
