package tun

import (
	"net"

	"github.com/metacubex/mihomo/common/lru"
	"github.com/metacubex/mihomo/component/process"
	C "github.com/metacubex/mihomo/constant"
)

type socketIdentity struct {
	uid  uint32
	name string
}

type socketKey struct {
	network C.NetWork
	source  string
	target  string
}

type attributingTunnel struct {
	C.Tunnel
	identities *lru.LruCache[socketKey, socketIdentity]
	lookup     process.PackageNameResolver
}

var appTunnel = attributingTunnel{
	identities: lru.New(lru.WithSize[socketKey, socketIdentity](16384), lru.WithAge[socketKey, socketIdentity](60)),
	lookup:     process.FindPackageName,
}

func metadataKey(metadata *C.Metadata) (socketKey, bool) {
	if metadata == nil || metadata.RawSrcAddr == nil || metadata.RawDstAddr == nil {
		return socketKey{}, false
	}
	return socketKey{metadata.NetWork, metadata.RawSrcAddr.String(), metadata.RawDstAddr.String()}, true
}

func (t *attributingTunnel) observe(metadata *C.Metadata) {
	key, ok := metadataKey(metadata)
	if !ok {
		return
	}
	if metadata.NetWork == C.UDP {
		if _, ok := t.identities.Get(key); ok {
			return
		}
	}
	// Android's owner lookup must run before sniffing/dialing can outlive the application's socket.
	resolved := *metadata
	name, err := t.lookup(&resolved)
	if err == nil && name != "" {
		t.identities.Set(key, socketIdentity{resolved.Uid, name})
	} else {
		t.identities.Delete(key)
	}
}

func (t *attributingTunnel) HandleTCPConn(conn net.Conn, metadata *C.Metadata) {
	t.observe(metadata)
	t.Tunnel.HandleTCPConn(conn, metadata)
}

func (t *attributingTunnel) HandleUDPPacket(packet C.UDPPacket, metadata *C.Metadata) {
	t.observe(metadata)
	t.Tunnel.HandleUDPPacket(packet, metadata)
}

func FindPackageName(metadata *C.Metadata) (string, error) {
	return appTunnel.findPackageName(metadata)
}

func (t *attributingTunnel) findPackageName(metadata *C.Metadata) (string, error) {
	if key, ok := metadataKey(metadata); ok {
		if identity, ok := t.identities.Get(key); ok {
			metadata.Uid = identity.uid
			return identity.name, nil
		}
	}
	return t.lookup(metadata)
}
