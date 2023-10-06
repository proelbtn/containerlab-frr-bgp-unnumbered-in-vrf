#!/bin/sh

set -ex

COUNT=1

if [ "$(docker ps | grep rt01)" != "" ]; then
	sudo clab -t manifest.yml destroy
fi

for c in $(seq $COUNT); do
	sudo clab -t manifest.yml deploy
	sleep 5

	sudo docker exec -it rt01 vtysh -c "show bgp vrf vrf1 ipv4 unicast"
	sudo docker exec -it rt01 vtysh -c "show bgp vrf vrf1 nexthop"

	sudo docker exec rt01 ip link delete eth2

	sudo docker exec -it rt01 vtysh -c "show bgp vrf vrf1 ipv4 unicast"
	sudo docker exec -it rt01 vtysh -c "show bgp vrf vrf1 nexthop"

	sudo clab -t manifest.yml destroy
done
