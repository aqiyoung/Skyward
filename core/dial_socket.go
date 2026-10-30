//go:build !android && !windows

package core

import (
	"fmt"
	"net"
)

func dial(arg string) (net.Conn, error) {
	// The Dart side always passes a unix socket path (unixSocketPath);
	// a numeric/TCP branch would let a crafted argument redirect the IPC
	// channel to loopback TCP, so only unix sockets are allowed.
	if len(arg) == 0 || arg[0] != '/' {
		return nil, fmt.Errorf("invalid socket path: %q", arg)
	}
	return net.Dial("unix", arg)
}
