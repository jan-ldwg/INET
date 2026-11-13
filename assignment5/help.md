# Helpful commands

|                                                 |                                             |
| ----------------------------------------------- | ------------------------------------------- |
| `sudo ip netns`                                 | Show all network namespaces                 |
| `sudo ip netns exec <ns> <cmd>`                 | Execute a command in a network namespace    |
| `ip -br a`                                      | Shows brief information for all interfaces  |
| `ip link set dev <if> up`                       | Enables an interface                        |
| `ip link add <name> type veth peer name <name>` | Add a link                                  |
| `ip link set <name> netns <ns>`                 | Assign end of a link to a network namespace |
