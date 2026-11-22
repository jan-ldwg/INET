#!/usr/bin/env python3
"""Basic Ethernet/IPv4/TCP PCAP generator for Question 3."""
import argparse
from scapy.all import Ether, IP, TCP, wrpcap


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("output")
    p.add_argument("src_mac")
    p.add_argument("dst_mac")
    args = p.parse_args()
    packets = [Ether(src=args.src_mac, dst=args.dst_mac) /
               IP(src="192.168.1.25", dst="198.18.1.1") /
               TCP(sport=40000, dport=80, flags="S")]
    # TODO: add packets for the remaining firewall rules.
    wrpcap(args.output, packets)


if __name__ == "__main__":
    main()
