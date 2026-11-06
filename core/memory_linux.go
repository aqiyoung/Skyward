//go:build linux || android

package core

import (
	"os"
	"strconv"
	"strings"
)

// probeDeviceMemory reads MemTotal from /proc/meminfo. Android exposes it to
// unprivileged apps, so the Core can size itself without the platform passing
// the figure down through the bridge.
func probeDeviceMemory() uint64 {
	data, err := os.ReadFile("/proc/meminfo")
	if err != nil {
		return 0
	}
	for _, line := range strings.Split(string(data), "\n") {
		if !strings.HasPrefix(line, "MemTotal:") {
			continue
		}
		fields := strings.Fields(line)
		if len(fields) < 2 {
			return 0
		}
		kilobytes, err := strconv.ParseUint(fields[1], 10, 64)
		if err != nil {
			return 0
		}
		return kilobytes << 10
	}
	return 0
}
