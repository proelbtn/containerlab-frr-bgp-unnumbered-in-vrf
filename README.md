# containerlab-frr-bgp-unnumbered-in-vrf

I checked this issue happened in FRR 8.5.x, 9.0.0, 9.0.1, master (86a5e5a04d).

## Reproduce log

After spawning FRR router with `sudo clab -t manifest.yml deploy`, we can access rt01 via `sudo docker exec -it rt01 vtysh`.

We can confirm that rt01 establish BGP peers to rt02 or rt03.

```text
$ sudo docker exec -it rt01 vtysh
% Can't open configuration file /etc/frr/vtysh.conf due to 'No such file or directory'.

Hello, this is FRRouting (version 8.5_git).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

rt01# show bgp vrf vrf1 summary

IPv4 Unicast Summary (VRF vrf1):
BGP router identifier 1.1.1.1, local AS number 1 vrf-id 2
BGP table version 1
RIB entries 1, using 192 bytes of memory
Peers 2, using 1435 KiB of memory
Peer groups 2, using 128 bytes of memory

Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
eth1            4          2        31        31        0    0    0 00:00:28            1        1 N/A
eth2            4          3        31        31        0    0    0 00:00:28            1        1 N/A

Total number of neighbors 2
```

We can also confirm that rt02 and rt03 advertise default route to rt01.

```text
rt01# show bgp vrf vrf1 ipv4 unicast
BGP table version is 1, local router ID is 1.1.1.1, vrf id 2
Default local pref 100, local AS 1
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

    Network          Next Hop            Metric LocPrf Weight Path
 *> 0.0.0.0/0        eth1                     0             0 2 i
 *=                  eth2                     0             0 3 i

Displayed  1 routes and 2 total paths
```

However, we can also confirm BGP nexthop cache is a little strange.

FRR will report that nexthop `fe80::a8c1:abff:fe4b:c8ec` and nexthop `fe80::a8c1:abff:fe83:28da` is connected to eth2. Of course, it's incorrect. `fe80::a8c1:abff:fe4b:c8ec` is a link local address of eth1 in RT02. So, FRR should report `fe80::a8c1:abff:fe4b:c8ec` is connected to eth1.

```text
rt01# show bgp vrf vrf1 nexthop
Current BGP nexthop cache:
 fe80::a8c1:abff:fe4b:c8ec valid [IGP metric 0], #paths 1
  if eth2
  Last update: Thu Oct  5 16:13:20 2023
 fe80::a8c1:abff:fe83:28da valid [IGP metric 0], #paths 1
  if eth2
  Last update: Thu Oct  5 16:13:20 2023
 fe80::a8c1:abff:fe83:28da valid [IGP metric 0], #paths 0, peer eth2
  Last update: Thu Oct  5 16:13:18 2023
 fe80::a8c1:abff:fe4b:c8ec valid [IGP metric 0], #paths 0, peer eth1
  Last update: Thu Oct  5 16:13:18 2023
```

```text
$ sudo docker exec -it rt02 ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
55: eth0@if56: <BROADCAST,MULTICAST> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:ac:14:14:04 brd ff:ff:ff:ff:ff:ff link-netnsid 0
59: eth1@if60: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP group default
    link/ether aa:c1:ab:4b:c8:ec brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::a8c1:abff:fe4b:c8ec/64 scope link
       valid_lft forever preferred_lft forever

$ sudo docker exec -it rt03 ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
53: eth0@if54: <BROADCAST,MULTICAST> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:ac:14:14:03 brd ff:ff:ff:ff:ff:ff link-netnsid 0
57: eth1@if58: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP group default
    link/ether aa:c1:ab:83:28:da brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::a8c1:abff:fe83:28da/64 scope link
       valid_lft forever preferred_lft forever
```

Under this situation, you can delete eth1 or eth2 in RT01 to reproduce IAAS-157039.

```
$ sudo docker exec rt01 ip link delete eth2

$ sudo docker exec -it rt01 vtysh
% Can't open configuration file /etc/frr/vtysh.conf due to 'No such file or directory'.

Hello, this is FRRouting (version 8.5_git).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

rt01# show bgp vrf vrf1 ipv4 unicast
BGP table version is 2, local router ID is 1.1.1.1, vrf id 2
Default local pref 100, local AS 1
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

    Network          Next Hop            Metric LocPrf Weight Path
    0.0.0.0/0        eth1                     0             0 2 i

Displayed  1 routes and 1 total paths
```

You can also check BGP nexthop cache is corrupted. `fe80::a8c1:abff:fe4b:c8ec` should be valid because we have not delete eth1 yet, but this nexthop is considered as invalid.

```
rt01# show bgp vrf vrf1 nexthop
Current BGP nexthop cache:
 fe80::a8c1:abff:fe4b:c8ec invalid, #paths 1
  Must be Connected
  Last update: Thu Oct  5 16:24:52 2023
 fe80::a8c1:abff:fe83:28da invalid, #paths 0, peer eth2
  Must be Connected
  Last update: Thu Oct  5 16:24:52 2023
 fe80::a8c1:abff:fe4b:c8ec valid [IGP metric 0], #paths 0, peer eth1
  Last update: Thu Oct  5 16:13:18 2023
```

