package tun

import (
	"errors"
	"net"
	"reflect"
	"testing"

	"github.com/metacubex/mihomo/common/lru"
	C "github.com/metacubex/mihomo/constant"
	P "github.com/metacubex/mihomo/constant/provider"
	"github.com/metacubex/mihomo/tunnel"
)

type recordingTunnel struct {
	tunnelDelegate
	onForward func(*C.Metadata)
}

func (t recordingTunnel) HandleTCPConn(_ net.Conn, metadata *C.Metadata)      { t.onForward(metadata) }
func (t recordingTunnel) HandleUDPPacket(_ C.UDPPacket, metadata *C.Metadata) { t.onForward(metadata) }

func TestAttributionPrecedesForwardingWithoutChangingRouting(t *testing.T) {
	for _, network := range []C.NetWork{C.TCP, C.UDP} {
		t.Run(network.String(), func(t *testing.T) {
			calls := 0
			wrapper := &attributingTunnel{
				identities: lru.New[socketKey, socketIdentity](),
				lookup: func(metadata *C.Metadata) (string, error) {
					calls++
					metadata.Uid = 10123
					return "com.facebook.katana", nil
				},
			}
			metadata := &C.Metadata{
				NetWork: network, Type: C.TUN,
				RawSrcAddr: &net.TCPAddr{IP: net.IPv4(10, 0, 0, 2), Port: 1234},
				RawDstAddr: &net.TCPAddr{IP: net.IPv4(1, 1, 1, 1), Port: 443},
			}
			wrapper.tunnelDelegate = recordingTunnel{onForward: func(forwarded *C.Metadata) {
				if calls != 1 {
					t.Fatal("owner lookup was delayed until after forwarding")
				}
				if forwarded != metadata || forwarded.Process != "" || forwarded.Uid != 0 {
					t.Fatal("statistics attribution changed routing metadata")
				}
				wrapper.lookup = func(*C.Metadata) (string, error) { return "", errors.New("socket has closed") }
				clone := *forwarded
				name, err := wrapper.findPackageName(&clone)
				if err != nil || name != "com.facebook.katana" || clone.Uid != 10123 {
					t.Fatalf("connection event lost the ingress identity: %q %v", name, err)
				}
			}}
			if network == C.TCP {
				wrapper.HandleTCPConn(nil, metadata)
			} else {
				wrapper.HandleUDPPacket(nil, metadata)
			}
		})
	}
}

func TestAttributingTunnelPreservesTunStartupInterfaces(t *testing.T) {
	wrapper := &attributingTunnel{tunnelDelegate: tunnel.Tunnel}
	var forwarding C.Tunnel = wrapper
	providers, ok := forwarding.(P.Tunnel)
	if !ok {
		t.Fatal("sing_tun.New requires provider.Tunnel in addition to constant.Tunnel")
	}
	if !reflect.DeepEqual(providers.Providers(), tunnel.Tunnel.Providers()) ||
		!reflect.DeepEqual(providers.RuleProviders(), tunnel.Tunnel.RuleProviders()) ||
		providers.RuleUpdateCallback() != tunnel.Tunnel.RuleUpdateCallback() {
		t.Fatal("TUN provider interfaces were not delegated to the original tunnel")
	}
}

func TestEmptyOwnerLookupIsRetried(t *testing.T) {
	calls := 0
	wrapper := &attributingTunnel{
		identities: lru.New[socketKey, socketIdentity](),
		lookup: func(metadata *C.Metadata) (string, error) {
			calls++
			if calls == 1 {
				return "", nil
			}
			metadata.Uid = 10123
			return "com.twitter.android", nil
		},
	}
	metadata := &C.Metadata{NetWork: C.UDP,
		RawSrcAddr: &net.UDPAddr{IP: net.IPv4(10, 0, 0, 2), Port: 1234},
		RawDstAddr: &net.UDPAddr{IP: net.IPv4(1, 1, 1, 1), Port: 443},
	}
	wrapper.observe(metadata)
	wrapper.observe(metadata)
	wrapper.observe(metadata)
	if calls != 2 {
		t.Fatalf("lookup calls = %d, want retry followed by cache hit", calls)
	}
	name, err := wrapper.findPackageName(metadata)
	if name != "com.twitter.android" || err != nil {
		t.Fatalf("resolved %q: %v", name, err)
	}
}
