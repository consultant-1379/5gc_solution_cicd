#!/bin/bash
#  1207   s1mme+n2
#  1204   s1u+n3-ran-1
#  1224   s1u+n3-ran-2
#  1205   toExt-open1-1
#  1225   toExt-open1-2
#  1202   sig_cn

ifconfig p1p1 up
ifconfig p3p1 up
ip link set dev p1p1_tap address b8:3f:d2:2b:0a:80
ip link set dev p3p1_tap address b8:3f:d2:2a:d7:f0
sudo ifconfig p1p1_tap up
sudo ifconfig p3p1_tap up

ip link add link p1p1_tap name vlan01207  type vlan id 1207 || true
ip link add link p1p1_tap name vlan01204  type vlan id 1204 || true
ip link add link p3p1_tap name vlan01224  type vlan id 1224 || true
ip link add link p1p1_tap name vlan01205  type vlan id 1205 || true
ip link add link p3p1_tap name vlan01225  type vlan id 1225 || true
ip link add link p3p1_tap name vlan01202  type vlan id 1202 || true




ip add add 172.30.49.101/24 dev vlan01207 || true
ip add add 172.30.48.101/24 dev vlan01204 || true
ip add add 172.30.50.101/24 dev vlan01224 || true
ip add add 172.30.64.101/24 dev vlan01205 || true
ip add add 172.30.66.101/24 dev vlan01225 || true
ip add add 172.30.16.101/24 dev vlan01202 || true




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

ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan01205
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan01205
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan01205


# NEF
route add -host 172.17.128.6/32 gw 172.30.16.1

/sbin/sysctl -w net.ipv4.ip_forward=1

