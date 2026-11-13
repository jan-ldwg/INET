#!/usr/bin/env bash
# Worksheet 5 submission template.
# Usage: sudo bash npa-05.sh setup|test|teardown
# Safe to source: only the supplied variable initializers and functions run here.
# Complete this file and students.csv, keeping their filenames unchanged.
# Submit the completed students.csv alongside your script.
# Keep the provided variable/function names and use the component variables.
# Replace each not_implemented call in (a)-(l) with that subtask's solution.
# Put all solution commands inside functions. Helpers go in the marked section.
# Leave the component definitions, supplied stage functions, and final guard intact.
# Initialize additional state inside functions.
# Check: bash check-submission.sh

# Namespace names.
NS_H1="H1"
NS_H2="H2"
NS_R1="R1"
NS_R2="R2"
NS_R3="R3"
NS_R4="R4"
NS_R5="R5"
NAMESPACES=("$NS_H1" "$NS_R1" "$NS_R2" "$NS_R3" "$NS_R4" "$NS_R5" "$NS_H2")
ROUTERS=("$NS_R1" "$NS_R2" "$NS_R3" "$NS_R4" "$NS_R5")

# Veth interface names, one variable for each end of every link.
IF_H1_R1="vH1"
IF_R1_H1="vR1-H1"
IF_R1_R2="vR1-R2"
IF_R2_R1="vR2-R1"
IF_R2_R3="vR2-R3"
IF_R3_R2="vR3-R2"
IF_R1_R4="vR1-R4"
IF_R4_R1="vR4-R1"
IF_R3_R5="vR3-R5"
IF_R5_R3="vR5-R3"
IF_R4_R5="vR4-R5"
IF_R5_R4="vR5-R4"
IF_H2_R5="vH2"
IF_R5_H2="vR5-H2"

# Subnets and endpoint addresses (addresses do not include a prefix length).
NET_H1_R1="2001:db8:1::/64"
IP_H1_R1="2001:db8:1::1"
IP_R1_H1="2001:db8:1::2"
NET_R1_R2="2001:db8:2::/64"
IP_R1_R2="2001:db8:2::1"
IP_R2_R1="2001:db8:2::2"
NET_R2_R3="2001:db8:3::/64"
IP_R2_R3="2001:db8:3::1"
IP_R3_R2="2001:db8:3::2"
NET_R1_R4="2001:db8:4::/64"
IP_R1_R4="2001:db8:4::1"
IP_R4_R1="2001:db8:4::2"
NET_R3_R5="2001:db8:5::/64"
IP_R3_R5="2001:db8:5::1"
IP_R5_R3="2001:db8:5::2"
NET_R4_R5="2001:db8:6::/64"
IP_R4_R5="2001:db8:6::1"
IP_R5_R4="2001:db8:6::2"
NET_H2_R5="2001:db8:7::/64"
IP_H2_R5="2001:db8:7::1"
IP_R5_H2="2001:db8:7::2"

# Router SIDs, also without a prefix length.
SID_R1="fc00:1::1"
SID_R2="fc00:2::1"
SID_R3="fc00:3::1"
SID_R4="fc00:4::1"
SID_R5="fc00:5::1"
ROUTER_SIDS=("$NS_R1 $SID_R1" "$NS_R2 $SID_R2" "$NS_R3 $SID_R3" "$NS_R4 $SID_R4" "$NS_R5 $SID_R5")

# Each link: namespace/interface/address at each end, subnet, expected direction.
LINKS=(
    "$NS_H1 $IF_H1_R1 $IP_H1_R1 $NS_R1 $IF_R1_H1 $IP_R1_H1 $NET_H1_R1 both"
    "$NS_R1 $IF_R1_R2 $IP_R1_R2 $NS_R2 $IF_R2_R1 $IP_R2_R1 $NET_R1_R2 request"
    "$NS_R2 $IF_R2_R3 $IP_R2_R3 $NS_R3 $IF_R3_R2 $IP_R3_R2 $NET_R2_R3 request"
    "$NS_R1 $IF_R1_R4 $IP_R1_R4 $NS_R4 $IF_R4_R1 $IP_R4_R1 $NET_R1_R4 reply"
    "$NS_R3 $IF_R3_R5 $IP_R3_R5 $NS_R5 $IF_R5_R3 $IP_R5_R3 $NET_R3_R5 request"
    "$NS_R4 $IF_R4_R5 $IP_R4_R5 $NS_R5 $IF_R5_R4 $IP_R5_R4 $NET_R4_R5 reply"
    "$NS_H2 $IF_H2_R5 $IP_H2_R5 $NS_R5 $IF_R5_H2 $IP_R5_H2 $NET_H2_R5 both"
)

CAPTURE_DIR="${NPA05_CAPTURE_DIR:-$PWD/npa-05-captures}"
CAPTURE_PIDS=()

not_implemented() {
    echo "TODO: implement $1" >&2
    return 1
}

# BEGIN SUBTASK FUNCTIONS: replace each TODO call with the corresponding solution.
# (a): Create all namespaces and bring their loopback interfaces up.
create_namespaces() {
    ip netns add $NS_H1
    ip netns exec $NS_H1 ip link set dev lo up
    ip netns add $NS_H2
    ip netns exec $NS_H2 ip link set dev lo up
    ip netns add $NS_R1
    ip netns exec $NS_R1 ip link set dev lo up
    ip netns add $NS_R2
    ip netns exec $NS_R2 ip link set dev lo up
    ip netns add $NS_R3
    ip netns exec $NS_R3 ip link set dev lo up
    ip netns add $NS_R4
    ip netns exec $NS_R4 ip link set dev lo up
    ip netns add $NS_R5
    ip netns exec $NS_R5 ip link set dev lo up
}

# (b): Create the veth links and move/enable each endpoint.
create_links() {
    not_implemented create_links
}

# (c): Assign the provided endpoint addresses with the corresponding prefixes.
assign_addresses() {
    not_implemented assign_addresses
}

# (d): Configure the default IPv6 route on each host.
configure_host_routes() {
    not_implemented configure_host_routes
}

# (e): Assign each router SID to its loopback interface.
assign_sids() {
    not_implemented assign_sids
}

# (f): Install routes to the remote router SIDs.
configure_sid_routes() {
    not_implemented configure_sid_routes
}

# (g): Enable IPv6 forwarding and SRv6 on the routers/interfaces.
enable_forwarding() {
    not_implemented enable_forwarding
}

# (h): Configure SID actions: End on R2/R3/R4, End.DT6 on R1/R5.
configure_end_actions() {
    not_implemented configure_end_actions
}

# (i): Configure the forward and return SRv6 paths.
configure_srv6_routes() {
    not_implemented configure_srv6_routes
}

# (j): Verify IPv6 connectivity from H1 to H2 with five echo requests.
# Probe-status globals remain available to verify_paths.
send_probes() {
    not_implemented send_probes
}

# (k): Accept start or stop: start/wait for captures, or stop/wait for them.
# Save captures under CAPTURE_DIR or another directory of your choice.
capture_traffic() {
    not_implemented capture_traffic
}

# (l): Check completed captures for both intended paths and wrong-path traffic.
verify_paths() {
    not_implemented verify_paths
}
# END SUBTASK FUNCTIONS

# BEGIN OPTIONAL HELPER FUNCTIONS
# Add helper function definitions here; do not call them outside functions.
# END OPTIONAL HELPER FUNCTIONS

# PROVIDED STAGE FUNCTIONS: leave these unchanged.
fail() {
    echo "Error: $*" >&2
    exit 1
}

teardown() {
    local ns existing
    existing=$(ip netns list)
    for ns in "${NAMESPACES[@]}"; do
        if awk -v ns="$ns" '$1 == ns { found=1 } END { exit !found }' <<< "$existing"; then
            # Deleting the namespaces also removes their veth links.
            ip netns delete "$ns"
        fi
    done
}

# Stage orchestration is supplied; implement the individual parts above.
setup() {
    teardown
    create_namespaces
    create_links
    assign_addresses
    configure_host_routes
    assign_sids
    configure_sid_routes
    enable_forwarding
    configure_end_actions
    configure_srv6_routes
    echo "Setup complete; the network remains available for inspection."
}

run_tests() {
    local cmd ns
    for cmd in tcpdump tshark ping; do
        command -v "$cmd" >/dev/null || fail "Install $cmd before running test."
    done
    for ns in "${NAMESPACES[@]}"; do
        ip netns exec "$ns" true || fail "Missing namespace $ns; run setup first."
    done
    trap 'capture_traffic stop || true' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    capture_traffic start
    send_probes
    capture_traffic stop
    verify_paths
    echo "Ok"
}

main() {
    # Sourcing the file does not change the harness's shell options.
    set -euo pipefail
    if [[ $# -ne 1 || ! "$1" =~ ^(setup|test|teardown)$ ]]; then
        echo "Usage: sudo bash $0 {setup|test|teardown}" >&2
        return 2
    fi
    [[ $EUID -eq 0 ]] || fail "Run this script with sudo."
    command -v ip >/dev/null || fail "Install iproute2 first."
    case "$1" in
        setup) setup ;;
        test) run_tests ;;
        teardown) teardown ;;
    esac
}

# Leave this guard unchanged: sourcing defines functions without calling main.
# The grading harness calls the subtask functions separately after sourcing.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
