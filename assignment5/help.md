# Helpful commands

|                                                                          |                                                                                              |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- | --- |
| `sudo ip netns`                                                          | Show all network namespaces                                                                  |
| `sudo ip netns exec <ns> <cmd>`                                          | Execute a command in a network namespace                                                     |
| `ip -br a`                                                               | Shows brief information for all interfaces                                                   |
| `ip link set dev <if> up`                                                | Enables an interface                                                                         |
| `ip link add <name> type veth peer name <name>`                          | Add a link                                                                                   |
| `ip link set <name> netns <ns>`                                          | Assign end of a link to a network namespace                                                  |
| `ip addr add <ip> dev <if>`                                              | Assigns an IP address to the interface                                                       |
| `sysctl -w net.ipv6.conf.all.forwarding=1`                               | Enables IPv6 forwarding                                                                      |
| `sysctl -w net.ipv6.conf.all.seg6_enabled=1`                             | Enables SRv6                                                                                 |
| `sysctl -w net.ipv6.conf.<if>.seg6_enabled=1`                            | Enables SRv6 on the interface                                                                |
| `ip -6 route`                                                            | Shows the routing table                                                                      |
| `ip -6 route add default via <ip>`                                       | Adds a default route                                                                         |
| `ip -6 route add <prefix> dev <if>`                                      | Add a route to forward this prefix to the interface                                          |
| `ip -6 route add <prefix> encap seg6 mode encap segs <seg,seg> dev <if>` | Adds a route which encapsulates the packet in the SRv6 headers and forwards on the interface |
| `ip route add <sid> encap seg6local action End dev lo`                   |
| `tcpdump -i <if>`                                                        |                                                                                              |     |
