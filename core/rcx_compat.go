package core

import (
	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outboundgroup"
	"github.com/metacubex/mihomo/constant"
)

// This fork does not gate request-traffic polling on the host being in the
// foreground the way ReClash does. RCX sends foreground hints over
// rcxSetHints; accepting and ignoring them keeps the protocol compatible
// without changing how traffic is sampled here.
func setHostForeground(foreground bool, seq uint64) {}

// proxyGroupOf unwraps an outbound to its group adapter. This fork has no
// scripted-group wrapper, so the direct assertion is the whole answer.
func proxyGroupOf(proxy constant.Proxy) (outboundgroup.ProxyGroup, bool) {
	outbound, ok := proxy.(*adapter.Proxy)
	if !ok {
		return nil, false
	}
	group, ok := outbound.ProxyAdapter.(outboundgroup.ProxyGroup)
	return group, ok
}
