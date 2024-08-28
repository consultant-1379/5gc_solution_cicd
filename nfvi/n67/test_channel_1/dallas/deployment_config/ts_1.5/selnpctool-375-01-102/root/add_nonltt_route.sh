#!/bin/bash


#ip link add link em1 name vlan0051  type vlan id 51
#ip add add 11.20.1.102/19 dev vlan0051
#ip link set vlan0051 up || true


route add -net 6.192.32.0/19 gw 11.20.1.201
route add -net 8.140.32.0/19 gw 11.20.1.201
route add -net 6.192.64.0/19 gw 11.20.1.202
route add -net 8.140.64.0/19 gw 11.20.1.202
