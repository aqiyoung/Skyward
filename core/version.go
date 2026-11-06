package core

import "github.com/metacubex/mihomo/constant"

// The version this core was built with, injected through `core_version` in
// build_config.yaml. The host announces it in the User-Agent it fetches
// profiles with, and providers pick the format they answer in from that
// string: a `clash.meta/<version>` prefix is what makes them return mihomo
// YAML instead of a share-link list. Reading the number from the build, rather
// than keeping a copy in the host, keeps that claim true every time the pin
// moves.
func handleCoreVersion() string {
	return constant.Version
}
