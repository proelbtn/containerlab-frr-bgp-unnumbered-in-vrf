#!/bin/sh

ip addr flush eth0
ip link set eth0 down

/usr/lib/frr/frrinit.sh start
 
while true; do sleep 365d; done
