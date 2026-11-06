package core

import (
	"context"
	"errors"
	"strings"
	"testing"
)

func TestShortDelayFailureKeepsTheFirstLine(t *testing.T) {
	err := errors.New("dial tcp 1.2.3.4:443: connect: connection refused\nwrapper: proxy node")
	if got := shortDelayFailure(err, nil); got != "dial tcp 1.2.3.4:443: connect: connection refused" {
		t.Fatalf("got %q", got)
	}
}

func TestShortDelayFailureTrimsByRunes(t *testing.T) {
	got := shortDelayFailure(errors.New(strings.Repeat("错", 300)), nil)
	runes := []rune(got)
	if len(runes) != 201 || runes[200] != '…' {
		t.Fatalf("got %d runes ending in %q", len(runes), string(runes[len(runes)-1]))
	}
}

func TestShortDelayFailureFallsBackToTheContext(t *testing.T) {
	got := shortDelayFailure(errors.New("  \n"), context.DeadlineExceeded)
	if got != context.DeadlineExceeded.Error() {
		t.Fatalf("got %q", got)
	}
}
