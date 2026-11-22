#!/usr/bin/env bash
# Question 3. Setup and cleanup are supplied; complete q3_replay.
NPA06_ROOT=$(dirname -- "${BASH_SOURCE[0]}")
NPA06_FIREWALL="$NPA06_ROOT/firewall.nft"
NPA06_OUT="$NPA06_ROOT/results-q3"
NS_Q3_TX=npa06-tx
NS_Q3_FW=npa06-fw

q3_setup() {
    ip netns add "$NS_Q3_TX"
    ip netns add "$NS_Q3_FW"
    ip -n "$NS_Q3_TX" link set lo up
    ip -n "$NS_Q3_FW" link set lo up
    ip -n "$NS_Q3_TX" link add tx type veth peer name rx netns "$NS_Q3_FW"
    ip -n "$NS_Q3_TX" link set tx address 02:00:00:00:06:01
    ip -n "$NS_Q3_FW" link set rx address 02:00:00:00:06:02
    ip -n "$NS_Q3_TX" link set tx up
    ip -n "$NS_Q3_FW" link set rx up
    ip netns exec "$NS_Q3_FW" nft -c -f "$NPA06_FIREWALL"
    ip netns exec "$NS_Q3_FW" nft -f "$NPA06_FIREWALL"
}

q3_replay() {
    # $1 = supplied PCAP. Replay from NS_Q3_TX/tx, wait for completion.
    # Save nft -j list ruleset from NS_Q3_FW to "$NPA06_OUT/q3-counters.json".
    echo 'TODO: q3_replay PCAP' >&2; return 2
}

cleanup() {
    ip netns del "$NS_Q3_TX" 2>/dev/null || true
    ip netns del "$NS_Q3_FW" 2>/dev/null || true
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    set -euo pipefail
    case ${1:-run} in
        run)
            mkdir -p "$NPA06_OUT"
            trap cleanup EXIT
            q3_setup
            python3 "$NPA06_ROOT/generate_packets.py" "$NPA06_OUT/packets.pcap" \
                02:00:00:00:06:01 02:00:00:00:06:02
            q3_replay "$NPA06_OUT/packets.pcap"
            ;;
        q3_setup|q3_replay|cleanup) "$@" ;;
        *) echo "Usage: bash $0 [run|cleanup|TASK [ARGUMENTS]]" >&2; exit 2 ;;
    esac
fi
