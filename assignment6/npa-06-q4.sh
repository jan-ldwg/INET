#!/usr/bin/env bash
# Question 4. The network and bottleneck setup is supplied.
# Complete only q4_fifo, q4_prio, q4_measure and q4_plot below.
NPA06_ROOT=$(dirname -- "${BASH_SOURCE[0]}")
NPA06_OUT="$NPA06_ROOT/results-q4"
NPA06_PING_ID=12345
NS_CLIENT=npa06-client
NS_ROUTER=npa06-router
NS_SERVER=npa06-server

q4_setup() {
    ip netns add "$NS_CLIENT"
    ip netns add "$NS_ROUTER"
    ip netns add "$NS_SERVER"
    for ns in "$NS_CLIENT" "$NS_ROUTER" "$NS_SERVER"; do
        ip -n "$ns" link set lo up
        ip netns exec "$ns" sysctl -qw net.ipv6.conf.all.disable_ipv6=1
        ip netns exec "$ns" sysctl -qw net.ipv6.conf.default.disable_ipv6=1
    done
    ip -n "$NS_CLIENT" link add eth0 type veth peer name lan netns "$NS_ROUTER"
    ip -n "$NS_ROUTER" link add wan type veth peer name eth0 netns "$NS_SERVER"
    ip -n "$NS_CLIENT" addr add 192.168.10.2/24 dev eth0
    ip -n "$NS_ROUTER" addr add 192.168.10.1/24 dev lan
    ip -n "$NS_ROUTER" addr add 203.0.113.1/24 dev wan
    ip -n "$NS_SERVER" addr add 203.0.113.2/24 dev eth0
    ip -n "$NS_CLIENT" link set eth0 up
    ip -n "$NS_ROUTER" link set lan up
    ip -n "$NS_ROUTER" link set wan up
    ip -n "$NS_SERVER" link set eth0 up
    ip -n "$NS_CLIENT" route add default via 192.168.10.1
    ip -n "$NS_SERVER" route add default via 203.0.113.1
    ip netns exec "$NS_ROUTER" sysctl -qw net.ipv4.ip_forward=1

    # Supplied 10 Mbit/s bottleneck; leave this block unchanged.
    ip netns exec "$NS_ROUTER" tc qdisc add dev wan root handle 1: htb default 1
    ip netns exec "$NS_ROUTER" tc class add dev wan parent 1: classid 1:1 htb \
        rate 10mbit ceil 10mbit burst 1500 cburst 1500
    ip netns exec "$NS_CLIENT" ping -n -c 1 -W 2 203.0.113.2 >/dev/null
}

q4_fifo() {
    # Already configured network. Replace the child of 1:1 by pfifo as in (b).
    # Supplied: clear the previous child before changing its qdisc type.
    ip netns exec "$NS_ROUTER" tc qdisc del dev wan parent 1:1 2>/dev/null || true
    # Base command: replace CONFIGURATION with the qdisc and its options.
    ip netns exec "$NS_ROUTER" tc qdisc replace dev wan parent 1:1 handle 10: pfifo limit 100
}

q4_prio() {
    # Already configured network. Replace that child by PRIO 10:, 3 bands,
    # priomap all1, per-band pfifo with the capacity from (d.1). Only ICMP echo requests ->10:1;
    # UDP/5000 and default ->10:2. Keep the supplied bottleneck setup unchanged.
    # Supplied: clear the FIFO before installing PRIO with the same handle.
    ip netns exec "$NS_ROUTER" tc qdisc del dev wan parent 1:1 2>/dev/null || true
    # Base command: replace CONFIGURATION with the qdisc and its options.
    ip netns exec "$NS_ROUTER" tc qdisc replace dev wan parent 1:1 handle 10: \
        prio bands 3 priomap 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1

    # add pfifo qdisc to every band
    ip netns exec "$NS_ROUTER" tc qdisc replace dev wan parent 10:1 handle 11: pfifo limit 100
    ip netns exec "$NS_ROUTER" tc qdisc replace dev wan parent 10:2 handle 12: pfifo limit 100
    ip netns exec "$NS_ROUTER" tc qdisc replace dev wan parent 10:3 handle 13: pfifo limit 100

    # assign icmp to band 0
    ip netns exec "$NS_ROUTER" tc filter replace dev wan parent 10: protocol ip prio 1 \
        flower ip_proto icmp type 8 code 0 classid 10:1 action pass

    # assign udp to band 1
    ip netns exec "$NS_ROUTER" tc filter replace dev wan parent 10: protocol ip prio 2 \
        flower ip_proto udp dst_port 5000 classid 10:2 action pass

}

q4_measure() {
    # $1 = fifo|prio, $2 = new output directory. Keep the existing network/qdisc.
    # Record ping while iperf3 sends a UDP flood; use Bash and standard tools.
    # Save original ping output and ping.csv (sequence,time_s,rtt_ms,lost).
    # Use real measurements; leave missing RTTs blank and wait for all workers.
    # In the PRIO run, inspect filters after traffic finishes, before cleanup.

    local mode="$1" out="$2"
    local count=200
    local server_pid ping_pid client_pid t0

    case "$mode" in
        fifo|prio) ;;
        *) echo "usage: q4_measure fifo|prio OUTDIR" >&2; return 1 ;;
    esac
    mkdir -p "$out" || return 1
    #export LC_ALL=C   # decimal point in ping output

    # iperf3 server in the server namespace (UDP dst port 5000, exits after one test)
    ip netns exec "$NS_SERVER" iperf3 -s -p 5000 -1 > "$out/iperf3_server.txt" 2>&1 &
    server_pid=$!
    sleep 1

    # ping 200 requests, 0.1s interval=20s
    t0=$(date +%s.%N)
    ip netns exec "$NS_CLIENT" ping -D -i 0.1 -c "$count" -W 1 203.0.113.2 > "$out/ping.txt" 2>&1 &
    ping_pid=$!

    # wait 5s, then udp flood for 10s
    (
        sleep 5
        ip netns exec "$NS_CLIENT" iperf3 -c 203.0.113.2 -u -b 20M -l 1200 \
            -p 5000 -t 10 > "$out/iperf3_client.txt" 2>&1
    ) &
    client_pid=$!

    # wait for ping and iperf to finish
    wait "$ping_pid"
    wait "$client_pid"
    # end the iperf server process if it didnt end itself already
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true

    # Qdisc statistics (both modes); filter statistics only in the PRIO run,
    # after the traffic has finished and before any cleanup
    ip netns exec "$NS_ROUTER" tc -s -d qdisc show dev wan > "$out/qdisc_stats.txt" 2>&1
    if [ "$mode" = prio ]; then
        ip netns exec "$NS_ROUTER" tc -s -d filter show dev wan parent 10: > "$out/filter_stats.txt" 2>&1
    fi

    # ping.csv: sequence,time_s,rtt_ms,lost  (lost pings: empty RTT, lost=1)
    awk -v t0="$t0" -v n="$count" -v iv=0.1 '
        /icmp_seq=/ && /time=/ {
            ts = $1; gsub(/[\[\]]/, "", ts)
            match($0, /icmp_seq=[0-9]+/); seq = substr($0, RSTART + 9, RLENGTH - 9) + 0
            match($0, /time=[0-9.]+/);    rtt = substr($0, RSTART + 5, RLENGTH - 5)
            rtt_of[seq] = rtt; ts_of[seq] = ts
        }
        END {
            print "sequence,time_s,rtt_ms,lost"
            for (i = 1; i <= n; i++) {
                if (i in rtt_of)   # send time = receive time - RTT - start
                    printf "%d,%.3f,%s,0\n", i, ts_of[i] - t0 - rtt_of[i] / 1000, rtt_of[i]
                else               # lost: nominal send time, RTT left blank
                    printf "%d,%.3f,,1\n", i, (i - 1) * iv
            }
        }' "$out/ping.txt" > "$out/ping.csv"
}

q4_plot() {
    # $1 contains fifo/ping.csv and prio/ping.csv. Produce one comparison
    # plot at "$1/plots/qos-ping.png" or "$1/plots/qos-ping.pdf" (or both).

    local root="$1"
    [ -n "$root" ] || { echo "usage: q4_plot ROOTDIR" >&2; return 1; }
    for m in fifo prio; do
        [ -r "$root/$m/ping.csv" ] || { echo "missing $root/$m/ping.csv" >&2; return 1; }
    done
    mkdir -p "$root/plots" || return 1

    python3 - "$root" <<'EOF'
import csv, math, sys
import matplotlib
matplotlib.use("Agg")                      # no display needed
import matplotlib.pyplot as plt

root = sys.argv[1]
runs = {"fifo": ("FIFO", "tab:red"), "prio": ("PRIO", "tab:blue")}
counts = []

fig, ax = plt.subplots(figsize=(10, 5))

# UDP flood active from t = 5 s to t = 15 s
ax.axvspan(5, 15, color="grey", alpha=0.2, label="UDP flood active (5-15 s)")

for key, (label, color) in runs.items():
    t, rtt = [], []
    sent = replied = 0
    with open(f"{root}/{key}/ping.csv", newline="") as f:
        for row in csv.DictReader(f):
            sent += 1
            t.append(float(row["time_s"]))
            if row["rtt_ms"].strip() == "":
                rtt.append(math.nan)       # lost: NaN -> gap in the line
            else:
                rtt.append(float(row["rtt_ms"]))
                replied += 1
    counts.append(f"{label}: sent={sent}, replied={replied}, lost={sent - replied}")
    # NaN breaks the line (gap); small markers keep isolated points visible
    ax.plot(t, rtt, color=color, linewidth=1.0, marker=".", markersize=3,
            label=f"{label} ({replied}/{sent} replies)")

ax.set_xlabel("Elapsed time (s)")
ax.set_ylabel("Ping RTT (ms)")
ax.set_xscale("linear")
ax.set_yscale("linear")
ax.set_xlim(left=0)
ax.set_ylim(bottom=0)
ax.set_title("Ping RTT under UDP flood: FIFO vs. PRIO")
ax.grid(True, alpha=0.3)
ax.legend(loc="upper right")
fig.tight_layout()
fig.savefig(f"{root}/plots/qos-ping.png", dpi=150)

text = "\n".join(counts)
print(text)
with open(f"{root}/plots/qos-ping-counts.txt", "w") as f:
    f.write(text + "\n")
EOF

}

cleanup() {
    ip netns del "$NS_CLIENT" 2>/dev/null || true
    ip netns del "$NS_ROUTER" 2>/dev/null || true
    ip netns del "$NS_SERVER" 2>/dev/null || true
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    set -euo pipefail
    case ${1:-run} in
        run)
            mkdir -p "$NPA06_OUT"
            trap cleanup EXIT
            q4_setup
            q4_fifo
            q4_measure fifo "$NPA06_OUT/fifo"
            q4_prio
            q4_measure prio "$NPA06_OUT/prio"
            q4_plot "$NPA06_OUT"
            ;;
        q4_setup|q4_fifo|q4_prio|q4_measure|q4_plot|cleanup) "$@" ;;
        *) echo "Usage: bash $0 [run|cleanup|TASK [ARGUMENTS]]" >&2; exit 2 ;;
    esac
fi
