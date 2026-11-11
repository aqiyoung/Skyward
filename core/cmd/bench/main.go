// Command bench measures what the tunnel costs, on one machine.
//
// The client, the core and the target all live here, so the number is the
// core's own capacity: the traffic goes through the tunnel, the rules and a
// proxy node, and never leaves the machine. That is the same shape as the
// measurement the Clash kernel publishes, and the only shape that can be
// compared across machines.
//
// The tunnel is brought up the way the application brings it up: QuickSetup
// applies the configuration, and applying it starts the listeners and the
// tunnel. The bare kernel binary starts neither, so it cannot be measured.
package main

import (
	"bufio"
	"crypto/rand"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"core"
)

// configYAML is the configuration the tunnel is measured with. The
// tunnel takes its address from the DNS fake-ip range, so the client asks
// for an address in that range and the tunnel's own subnet route carries
// it; no name is ever looked up.
func configYAML(stack string) string {
	kernelStack := "mips"
	if stack == "go" {
		kernelStack = "go"
	}
	return fmt.Sprintf(`mixed-port: 17890
mode: rule
log-level: warning
ipv6: false
dns:
  enable: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
proxies:
  - name: local
    type: http
    server: 127.0.0.1
    port: 17891
rules:
  - MATCH,local
tun:
  enable: true
  stack: %s
  device: skyward-bench
  auto-route: false
  auto-detect-interface: false
`, kernelStack)
}

const (
	targetPort = 18080
	proxyPort  = 17891
	// The tunnel takes its address from the DNS fake-ip range, so this is
	// the address the client asks for. The tunnel's own subnet route
	// carries it, and no name is ever looked up.
	clientAddress = "198.18.0.2"
)

func main() {
	stack := flag.String("stack", "legacy", "the tun stack to measure: legacy or go")
	runs := flag.Int("runs", 3, "how many times to measure")
	sizeMiB := flag.Int("size", 64, "the payload size in MiB")
	flag.Parse()

	home, err := os.MkdirTemp("", "skyward-bench-")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(home)

	payload := make([]byte, sizeMiB*1024*1024)
	if _, err := rand.Read(payload); err != nil {
		panic(err)
	}

	// The target.
	target, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", targetPort))
	if err != nil {
		panic(err)
	}
	defer target.Close()
	go http.Serve(target, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Length", strconv.Itoa(len(payload)))
		_, _ = w.Write(payload)
	}))

	// The proxy node. It reaches the target whatever address it was asked
	// for, which is what keeps the traffic on this machine.
	proxy, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", proxyPort))
	if err != nil {
		panic(err)
	}
	defer proxy.Close()
	go serveProxy(proxy)

	// The core, the way the application starts it.
	configPath := filepath.Join(home, "config.yaml")
	if err := os.WriteFile(configPath, []byte(configYAML(*stack)), 0o644); err != nil {
		panic(err)
	}
	initParams := fmt.Sprintf(`{"home-dir": %q, "version": 1}`, home)
	setupParams := fmt.Sprintf(`{"base": {"path": %q}}`, configPath)
	done := make(chan string, 1)
	core.QuickSetup(initParams, setupParams, func(answer string) { done <- answer })
	if answer := <-done; answer != "" {
		fmt.Fprintln(os.Stderr, "the core did not take the configuration:", answer)
		os.Exit(1)
	}
	defer core.StopListener()

	url := fmt.Sprintf("http://%s:%d/payload.bin", clientAddress, targetPort)
	fmt.Printf("stack=%s runs=%d size=%dMiB\n", *stack, *runs, *sizeMiB)

	best := 0.0
	for run := 1; run <= *runs; run++ {
		start := time.Now()
		response, err := http.Get(url)
		if err != nil {
			fmt.Fprintln(os.Stderr, "the transfer failed:", err)
			os.Exit(1)
		}
		read, err := io.Copy(io.Discard, response.Body)
		_ = response.Body.Close()
		if err != nil {
			fmt.Fprintln(os.Stderr, "the transfer failed:", err)
			os.Exit(1)
		}
		elapsed := time.Since(start)
		speed := float64(read) / 1048576 / elapsed.Seconds()
		if speed > best {
			best = speed
		}
		fmt.Printf("run %d: %.1f MiB/s (%d bytes in %s)\n", run, speed, read, elapsed.Round(time.Millisecond))
	}
	fmt.Printf("best: %.1f MiB/s\n", best)
}

func serveProxy(listener net.Listener) {
	for {
		client, err := listener.Accept()
		if err != nil {
			return
		}
		go handleProxy(client)
	}
}

func handleProxy(client net.Conn) {
	defer client.Close()
	request, err := http.ReadRequest(bufio.NewReader(client))
	if err != nil {
		return
	}
	upstream, err := net.Dial("tcp", fmt.Sprintf("127.0.0.1:%d", targetPort))
	if err != nil {
		return
	}
	defer upstream.Close()
	if request.Method == http.MethodConnect {
		_, _ = client.Write([]byte("HTTP/1.1 200 Connection Established\r\n\r\n"))
	} else {
		// The request line carries the path only, so the target can serve it.
		request.URL.Scheme = ""
		request.URL.Host = ""
		request.RequestURI = ""
		if err := request.Write(upstream); err != nil {
			return
		}
	}
	go func() {
		_, _ = io.Copy(upstream, client)
		_ = upstream.Close()
	}()
	_, _ = io.Copy(client, upstream)
}
