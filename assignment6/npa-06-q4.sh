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
    # ip netns exec "$NS_ROUTER" tc qdisc replace dev wan parent 1:1 handle 10: CONFIGURATION
    echo 'TODO: q4_fifo' >&2; return 2
}

q4_prio() {
    # Already configured network. Replace that child by PRIO 10:, 3 bands,
    # priomap all1, per-band pfifo with the capacity from (d.1). Only ICMP echo requests ->10:1;
    # UDP/5000 and default ->10:2. Keep the supplied bottleneck setup unchanged.
    # Supplied: clear the FIFO before installing PRIO with the same handle.
    ip netns exec "$NS_ROUTER" tc qdisc del dev wan parent 1:1 2>/dev/null || true
    # Base command: replace CONFIGURATION with the qdisc and its options.
    # ip netns exec "$NS_ROUTER" tc qdisc replace dev wan parent 1:1 handle 10: CONFIGURATION
    echo 'TODO: q4_prio' >&2; return 2
}

q4_measure() {
    # $1 = fifo|prio, $2 = new output directory. Keep the existing network/qdisc.
    # Record ping while iperf3 sends a UDP flood; use Bash and standard tools.
    # Save original ping output and ping.csv (sequence,time_s,rtt_ms,lost).
    # Use real measurements; leave missing RTTs blank and wait for all workers.
    # In the PRIO run, inspect filters after traffic finishes, before cleanup.
    echo 'TODO: q4_measure MODE OUTDIR' >&2; return 2
}

q4_plot() {
    # $1 contains fifo/ping.csv and prio/ping.csv. Produce one comparison
    # plot at "$1/plots/qos-ping.png" or "$1/plots/qos-ping.pdf" (or both).
    echo 'TODO: q4_plot ROOTDIR' >&2; return 2
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
