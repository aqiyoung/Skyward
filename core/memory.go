package core

import (
	"runtime/debug"
	"sync/atomic"
)

const (
	// The Core shares one process with the Flutter engine, and on Android with
	// the whole UI. It only ever needs a slice of the device's RAM: an unbounded
	// heap is what turns a backgrounded client into the first OOM candidate.
	//
	// The floor still fits a large rule set (a few hundred thousand entries)
	// while leaving the rest of the process its share.
	minMemoryLimit = 128 << 20
	maxMemoryLimit = 384 << 20
)

var (
	deviceMemoryTotal atomic.Uint64
	memoryLimit       atomic.Int64
	gcPercent         atomic.Int32
	budgetApplied     atomic.Bool
)

// memoryBudget maps physical RAM to a soft heap limit and a GC target.
//
// The limit is the hard ceiling the collector works against; the percentage
// decides how much above the live heap it is allowed to drift before collecting.
// Both scale with the device, because a 3 GiB phone and a 16 GiB phone want very
// different answers.
func memoryBudget(total uint64) (limit int64, percent int) {
	switch {
	case total == 0:
		// Size unknown: keep the runtime defaults rather than guess.
		return 0, 0
	case total <= 3<<30:
		return minMemoryLimit, 50
	case total <= 5<<30:
		return 160 << 20, 50
	case total <= 7<<30:
		return 224 << 20, 60
	case total <= 10<<30:
		return 288 << 20, 70
	default:
		return maxMemoryLimit, 70
	}
}

// applyMemoryBudget installs the limit once, before the first config load, so
// the collector never has to walk a heap that grew under default settings.
func applyMemoryBudget() {
	if budgetApplied.Swap(true) {
		return
	}
	total := probeDeviceMemory()
	deviceMemoryTotal.Store(total)
	limit, percent := memoryBudget(total)
	if limit == 0 {
		return
	}
	debug.SetMemoryLimit(limit)
	debug.SetGCPercent(percent)
	memoryLimit.Store(limit)
	gcPercent.Store(int32(percent))
}

// currentMemoryLimit reports the soft limit in force, 0 when the runtime default
// is still in place.
func currentMemoryLimit() int64 {
	return memoryLimit.Load()
}
