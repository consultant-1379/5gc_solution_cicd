#!/bin/bash


#ip link add link em1 name vlan0051  type vlan id 51
#ip add add 11.20.1.102/19 dev vlan0051
#ip link set vlan0051 up || true

route add -net 6.192.0.0/18 gw 11.20.1.201 || true
route add -net 8.140.0.0/18 gw 11.20.1.201 || true
route add -net 6.192.64.0/18 gw 11.20.1.202 || true
route add -net 8.140.64.0/18 gw 11.20.1.202 || true
route add -host 10.132.128.136 gw 11.20.1.201 || true
route add -host 10.132.144.136 gw 11.20.1.201 || true
route add -net 10.132.128.96/29 gw 11.20.1.201 || true
route add -net 10.132.144.96/29 gw 11.20.1.201 || true

/sbin/sysctl -w net.ipv4.ip_forward=1