#!/bin/bash


#ip link add link em1 name vlan0051  type vlan id 51
#ip add add 11.20.1.101/24 dev vlan0051
#ip link set vlan0051 up || true

#route add -net 8.148.0.0/19 gw 11.20.1.201 || true
#route add -net 8.140.0.0/19 gw 11.20.1.201 || true
route add -net 172.16.64.0/24 gw 11.20.1.201 || true
route add -host 172.17.128.6/32 gw 11.20.1.201 || true
