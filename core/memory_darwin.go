//go:build darwin || ios

package core

import (
	"encoding/binary"
	"syscall"
)

// probeDeviceMemory asks the kernel for hw.memsize, which returns the total
// installed RAM as a little-endian uint64.
func probeDeviceMemory() uint64 {
	value, err := syscall.Sysctl("hw.memsize")
	if err != nil {
		return 0
	}
	raw := []byte(value)
	if len(raw) < 8 {
		return 0
	}
	return binary.LittleEndian.Uint64(raw[:8])
}
