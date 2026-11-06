//go:build !linux && !android && !darwin && !ios

package core

// probeDeviceMemory has no portable answer here, so the Core keeps the runtime
// defaults instead of inventing a budget.
func probeDeviceMemory() uint64 {
	return 0
}
