#!/bin/bash

#  141   signaling
#  1207   s1mme+n2
#  1204   s1u+n3-ran-1
#  1224   s1u+n3-ran-2
#  1205   toExt-open1-1
#  1225   toExt-open1-2
#  1202   sig_cn
#ip link add link em1 name vlan0051  type vlan id 51 || true
#ip add add 11.20.1.201/19 dev vlan0051 ||true
#ip link set vlan0051 up ||true

#ip link add link p1p1_tap name vlan0141  type vlan id 141 || true
ip link add link p1p1_tap name vlan01207  type vlan id 1207 || true
ip link add link p1p1_tap name vlan01204  type vlan id 1204 || true
ip link add link p3p1_tap name vlan01224  type vlan id 1224 || true
ip link add link p1p1_tap name vlan01205  type vlan id 1205 || true
ip link add link p3p1_tap name vlan01225  type vlan id 1225 || true
ip link add link p3p1_tap name vlan01202  type vlan id 1202 || true



ip add add 172.30.49.102/24 dev vlan01207 || true
ip add add 172.30.48.102/24 dev vlan01204 || true
ip add add 172.30.50.102/24 dev vlan01224 || true
ip add add 172.30.64.102/24 dev vlan01205 || true
ip add add 172.30.66.102/24 dev vlan01225 || true
ip add add 172.30.16.102/24 dev vlan01202 || true

ip add add fdac:30:64::102/64 dev vlan01205 || true
ip add add fdac:30:66::102/64 dev vlan01225 || true



ip link set vlan01207 up || true
ip link set vlan01204 up || true
ip link set vlan01224 up || true
ip link set vlan01205 up || true
ip link set vlan01225 up || true
ip link set vlan01202 up || true



# s1mme n2

route add -host 172.16.64.1/32 gw 172.30.49.1
route add -host 172.16.64.2/32 gw 172.30.49.1
route add -host 172.16.64.3/32 gw 172.30.49.1
route add -host 172.16.64.4/32 gw 172.30.49.1


#### GnodeB N2
route add -net 8.128.0.0/19 gw 11.20.1.101
route add -net 8.128.32.0/19 gw 11.20.1.102

#### EnodeB  S1MME
route add -net 8.136.0.0/19 gw 11.20.1.101
route add -net 8.136.32.0/19 gw 11.20.1.102

#### NEF
route add -host 172.17.128.6/32 gw 172.30.16.1

/sbin/sysctl -w net.ipv4.ip_forward=1

