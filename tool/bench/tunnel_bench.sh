#!/usr/bin/env bash
# Measures what the tunnel costs, on one machine, without touching the network.
#
# The traffic goes through the tunnel, the rules and the outbound, and comes
# back to the same machine: the client, the core and the target all live here,
# so the number is the core's own processing capacity and nothing else. That
# is the same shape as the measurement the Clash kernel publishes, and it is
# the only shape that can be compared across machines.
#
# Two modes:
#
#   --mode tun     the client's packets go through the tunnel device, so the
#                  user space stack (gVisor, mips, the go stack) is measured.
#                  Needs a core binary and, on macOS and Linux, root: the
#                  tunnel device and its routes are the system's.
#   --mode proxy   the client's packets go straight into the core's inbound.
#                  Measures the relay path (splice, copy blocks, buffers)
#                  without the tunnel device.
#
# The core binary is not built here. Get one from CI or from a release, and
# point --core at it.
#
# Usage:
#   tool/bench/tunnel_bench.sh --core /path/to/SkywardCore [--mode tun|proxy]
#                               [--stack legacy|go] [--size 256] [--runs 3]

set -euo pipefail

mode=tun
stack=legacy
size_mib=256
runs=3
core_bin=""
target_port=18080
mixed_port=17890
file_name="payload.bin"

usage() {
  sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --core) core_bin="$2"; shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
    --stack) stack="$2"; shift 2 ;;
    --size) size_mib="$2"; shift 2 ;;
    --runs) runs="$2"; shift 2 ;;
    --help|-h) usage 0 ;;
    *) echo "unknown argument: $1" >&2; usage 1 ;;
  esac
done

if [[ -z "$core_bin" ]]; then
  echo "--core is required" >&2
  usage 1
fi
if [[ ! -x "$core_bin" ]]; then
  echo "the core binary is not executable: $core_bin" >&2
  exit 1
fi
if ! command -v curl >/dev/null; then
  echo "curl is required" >&2
  exit 1
fi
if ! command -v python3 >/dev/null; then
  echo "python3 is required (it serves the target)" >&2
  exit 1
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/skyward-bench.XXXXXX")"
core_pid=""
target_pid=""
cleanup() {
  [[ -n "$core_pid" ]] && kill "$core_pid" 2>/dev/null || true
  [[ -n "$target_pid" ]] && kill "$target_pid" 2>/dev/null || true
  rm -rf "$work_dir"
}
trap cleanup EXIT

# The target serves a file big enough that the transfer lasts longer than the
# sampling interval, so the CPU and memory numbers describe the transfer and
# not the setup.
head -c "$((size_mib * 1024 * 1024))" /dev/urandom > "$work_dir/$file_name"

# A domain that resolves to this machine. The tunnel mode reaches it through
# the fake-ip range, so the client can ask for an address the tunnel owns and
# the core still knows the real destination.
if [[ "$mode" == "tun" ]]; then
  tun_enable=true
  # "legacy" is the stack the kernel runs today. The configuration has to name
  # a stack, so the name is spelled out here.
  tun_stack=mips
else
  tun_enable=false
  tun_stack=mips
fi
if [[ "$stack" != "legacy" ]]; then
  tun_stack="$stack"
fi

cat > "$work_dir/config.yaml" <<EOF
mixed-port: $mixed_port
allow-lan: false
mode: rule
log-level: warning
ipv6: false
dns:
  enable: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  listen: 127.0.0.1:1053
  nameserver:
    - 127.0.0.1
hosts:
  bench.invalid: 127.0.0.1
tun:
  enable: $tun_enable
  stack: $tun_stack
  device: skyward-bench
  auto-route: true
  auto-detect-interface: true
  inet4-address:
    - 172.31.0.1/30
  dns-hijack:
    - 0.0.0.0:53
rules:
  - MATCH,DIRECT
EOF

python3 - "$work_dir" "$target_port" <<'PY' &
import http.server
import os
import sys

directory, port = sys.argv[1], int(sys.argv[2])
os.chdir(directory)


class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
PY
target_pid=$!
sleep 1

if ! curl --silent --fail --max-time 5 -o /dev/null "http://127.0.0.1:$target_port/$file_name"; then
  echo "the target server did not come up on 127.0.0.1:$target_port" >&2
  exit 1
fi

# The tunnel device and its routes are the system's, so the core needs root on
# macOS and Linux. On Windows the driver asks for the privilege itself.
run_core() {
  if [[ "$(uname -s)" == "Darwin" || "$(uname -s)" == "Linux" ]]; then
    if [[ "${SKYWARD_BENCH_SUDO:-1}" == "1" ]]; then
      sudo -n "$core_bin" -d "$work_dir" -f "$work_dir/config.yaml" &
    else
      "$core_bin" -d "$work_dir" -f "$work_dir/config.yaml" &
    fi
  else
    "$core_bin" -d "$work_dir" -f "$work_dir/config.yaml" &
  fi
  core_pid=$!
  sleep 3
  if ! kill -0 "$core_pid" 2>/dev/null; then
    echo "the core did not stay up; its log is in $work_dir" >&2
    exit 1
  fi
}
run_core

# In tunnel mode the client asks for an address the tunnel owns: the fake-ip
# range. The core maps it back to bench.invalid, which the hosts entry sends
# to this machine. In proxy mode the client talks to the inbound directly.
if [[ "$mode" == "tun" ]]; then
  url="http://198.18.0.2:$target_port/$file_name"
  proxy_arg=()
else
  url="http://127.0.0.1:$target_port/$file_name"
  proxy_arg=(--proxy "http://127.0.0.1:$mixed_port")
fi

sample_process() {
  # ps prints the same columns on macOS and Linux.
  ps -o %cpu=,rss= -p "$core_pid" 2>/dev/null | tr -s ' ' | sed 's/^ //'
}

echo "mode=$mode stack=$stack size=${size_mib}MiB runs=$runs"
echo "core pid $core_pid, target 127.0.0.1:$target_port"

results=()
for run in $(seq 1 "$runs"); do
  peak_rss=0
  sum_cpu=0
  samples=0

  (
    while kill -0 "$core_pid" 2>/dev/null; do
      read -r cpu rss < <(sample_process) || true
      [[ -n "${rss:-}" ]] && echo "$cpu $rss" >> "$work_dir/samples"
      sleep 0.5
    done
  ) &
  sampler=$!

  speed=$(curl --silent --output /dev/null --write-out '%{speed_download}' \
    --max-time 600 "${proxy_arg[@]}" "$url")
  kill "$sampler" 2>/dev/null || true
  wait "$sampler" 2>/dev/null || true

  if [[ -s "$work_dir/samples" ]]; then
    peak_rss=$(awk '{ if ($2 > max) max = $2 } END { print max + 0 }' "$work_dir/samples")
    sum_cpu=$(awk '{ total += $1 } END { print total + 0 }' "$work_dir/samples")
    samples=$(wc -l < "$work_dir/samples" | tr -d ' ')
  fi
  : > "$work_dir/samples"

  mib_s=$(awk -v s="$speed" 'BEGIN { printf "%.1f", s / 1048576 }')
  cpu_avg=$(awk -v c="$sum_cpu" -v n="$samples" 'BEGIN { printf "%.0f", (n > 0 ? c / n : 0) }')
  rss_mib=$(awk -v r="$peak_rss" 'BEGIN { printf "%.1f", r / 1024 }')
  echo "run $run: ${mib_s} MiB/s  cpu ${cpu_avg}%  peak rss ${rss_mib} MiB"
  results+=("$mib_s")
done

printf '%.0f\n' "${results[@]}" | sort -n | awk '
  { values[NR] = $1 }
  END {
    mid = int((NR + 1) / 2)
    printf "median: %.1f MiB/s\n", values[mid]
    printf "best:  %.1f MiB/s\n", values[NR]
  }'
