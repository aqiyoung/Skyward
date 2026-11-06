package core

import (
	"runtime/debug"
	"testing"
)

func TestMemoryBudgetTiers(t *testing.T) {
	cases := []struct {
		name    string
		total   uint64
		limit   int64
		percent int
	}{
		{"unknown device", 0, 0, 0},
		{"2 GiB", 2 << 30, 128 << 20, 50},
		{"3 GiB boundary", 3 << 30, 128 << 20, 50},
		{"4 GiB", 4 << 30, 160 << 20, 50},
		{"5 GiB boundary", 5 << 30, 160 << 20, 50},
		{"6 GiB", 6 << 30, 224 << 20, 60},
		{"8 GiB", 8 << 30, 288 << 20, 70},
		{"12 GiB", 12 << 30, 384 << 20, 70},
		{"64 GiB", 64 << 30, 384 << 20, 70},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			limit, percent := memoryBudget(c.total)
			if limit != c.limit || percent != c.percent {
				t.Fatalf(
					"memoryBudget(%d) = (%d, %d), want (%d, %d)",
					c.total, limit, percent, c.limit, c.percent,
				)
			}
		})
	}
}

// The budget has to stay inside the band the collector can actually live with:
// too low and a large rule set thrashes, too high and the app is the first thing
// the low-memory killer takes.
func TestMemoryBudgetStaysInBand(t *testing.T) {
	for total := uint64(1 << 30); total <= 32<<30; total += 1 << 30 {
		limit, percent := memoryBudget(total)
		if limit < minMemoryLimit || limit > maxMemoryLimit {
			t.Fatalf("memoryBudget(%d) limit %d outside [%d, %d]", total, limit, minMemoryLimit, maxMemoryLimit)
		}
		if percent < 40 || percent > 80 {
			t.Fatalf("memoryBudget(%d) gave gc percent %d, outside a range that trades CPU sanely", total, percent)
		}
	}
}

func TestApplyMemoryBudgetInstallsLimitOnce(t *testing.T) {
	t.Cleanup(func() {
		debug.SetMemoryLimit(-1)
		debug.SetGCPercent(-1)
		budgetApplied.Store(false)
		memoryLimit.Store(0)
		gcPercent.Store(0)
		deviceMemoryTotal.Store(0)
	})
	budgetApplied.Store(false)
	memoryLimit.Store(0)
	gcPercent.Store(0)

	applyMemoryBudget()

	total := deviceMemoryTotal.Load()
	if total == 0 {
		t.Skip("device memory is not readable on this platform")
	}
	wantLimit, wantPercent := memoryBudget(total)
	if got := currentMemoryLimit(); got != wantLimit {
		t.Fatalf("limit = %d, want %d", got, wantLimit)
	}
	if got := gcPercent.Load(); got != int32(wantPercent) {
		t.Fatalf("gc percent = %d, want %d", got, wantPercent)
	}

	// A second call must leave the installed budget alone; startup paths can run
	// init more than once.
	memoryLimit.Store(-1)
	applyMemoryBudget()
	if got := currentMemoryLimit(); got != -1 {
		t.Fatalf("second apply overwrote the limit: %d", got)
	}
}

func TestProbeDeviceMemoryReadsTotal(t *testing.T) {
	total := probeDeviceMemory()
	if total == 0 {
		t.Skip("device memory is not readable on this platform")
	}
	if total < 256<<20 {
		t.Fatalf("probeDeviceMemory returned %d, too small to be physical RAM", total)
	}
}
