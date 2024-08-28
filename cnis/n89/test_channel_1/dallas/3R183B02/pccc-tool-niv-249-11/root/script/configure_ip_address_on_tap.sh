#!/bin/bash
#  1207   s1mme+n2
#  1204   s1u+n3-ran-1
#  1224   s1u+n3-ran-2
#  1205   toExt-open1-1
#  1225   toExt-open1-2
#  1202   sig_cn

ip link add link p1p1_tap name vlan01207  type vlan id 1207 || true
ip link add link p1p1_tap name vlan01204  type vlan id 1204 || true
ip link add link p2p1_tap name vlan01224  type vlan id 1224 || true
ip link add link p1p1_tap name vlan01205  type vlan id 1205 || true
ip link add link p2p1_tap name vlan01225  type vlan id 1225 || true
ip link add link p2p1_tap name vlan01202  type vlan id 1202 || true



ip add add 172.30.49.105/24 dev vlan01207 || true
ip add add 172.30.48.105/24 dev vlan01204 || true
ip add add 172.30.50.105/24 dev vlan01224 || true
ip add add 172.30.64.105/24 dev vlan01205 || true
ip add add 172.30.66.105/24 dev vlan01225 || true
ip add add 172.30.16.105/24 dev vlan01202 || true

ip add add fdac:30:64::105/64 dev vlan01205 || true
ip add add fdac:30:66::105/64 dev vlan01225 || true



ip link set vlan01207 up || true
ip link set vlan01204 up || true
ip link set vlan01224 up || true
ip link set vlan01205 up || true
ip link set vlan01225 up || true


# s1mme n2

route add -host 172.16.64.1/32 gw 172.30.49.1
route add -host 172.16.64.2/32 gw 172.30.49.1
route add -host 172.16.64.3/32 gw 172.30.49.1
route add -host 172.16.64.4/32 gw 172.30.49.1

# NEF
route add -host 172.17.128.6/32 gw 172.30.16.1

/sbin/sysctl -w net.ipv4.ip_forward=1

