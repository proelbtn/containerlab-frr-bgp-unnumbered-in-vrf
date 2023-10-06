#!/bin/sh

ip addr flush eth0
ip link set eth0 down

while [ "$(ip link | grep eth1)" == "" ]; do sleep 0.1; done
while [ "$(ip link | grep eth2)" == "" ]; do sleep 0.1; done

ip link add name vrf1 type vrf table 1000
ip link set vrf1 up
ip link set eth1 vrf vrf1
ip link set eth2 vrf vrf1

/usr/lib/frr/frrinit.sh start
 
while true; do sleep 365d; done
