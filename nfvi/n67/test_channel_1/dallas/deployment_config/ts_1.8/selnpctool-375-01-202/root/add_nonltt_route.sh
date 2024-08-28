#!/bin/bash

#  141   signaling
#  143   ran-1
#  153   ran-2
#  144   sgi1-1
#  154   sgi1-2

#ip link add link em1 name vlan0051  type vlan id 51 || true
#ip add add 11.20.1.202/19 dev vlan0051 ||true
#ip link set vlan0051 up ||true

ip link add link p3p1_tap name vlan0141  type vlan id 141 || true
ip link add link p3p1_tap name vlan0143  type vlan id 143 || true
ip link add link p3p1_tap name vlan0144  type vlan id 144 || true
ip link add link p1p1_tap name vlan0154  type vlan id 154 || true
ip link add link p1p1_tap name vlan0153  type vlan id 153 || true

ip add add 11.100.2.6/24 dev vlan0141 || true
ip add add 11.100.30.6/24 dev vlan0154 || true
#ip add add 2a00:11.100.30::2/64 dev vlan0154 || true
ip add add 11.100.29.6/24 dev vlan0153 || true
ip add add 11.100.5.6/24 dev vlan0144 || true
#ip add add 2a00:11.100.5::2/64 dev vlan0144 || true
ip add add 11.100.4.6/24 dev vlan0143 || true
ip link set vlan0153 up || true
ip link set vlan0154 up || true
ip link set vlan0143 up || true
ip link set vlan0144 up || true
ip link set vlan0141 up || true

#ifconfig lo:00 8.8.1.6/32 up || true


# amf n2

route add -net 10.132.128.96/29 gw 11.100.4.254
route add -net 10.132.144.96/29 gw 11.100.29.254

#### GnodeB N2
route add -net 6.192.0.0/18 gw 11.20.1.102
route add -net 6.192.64.0/18 gw 11.20.1.103

### mme S1
route add -host 10.132.128.136/32 gw 11.100.4.254
route add -host 10.132.144.136/32 gw 11.100.29.254

#### EnodeB  S1C
route add -net 8.140.0.0/18 gw 11.20.1.102
route add -net 8.140.64.0/18 gw 11.20.1.103

##### MME  S6a
route add -net 106.102.0.64/27 gw 11.100.2.254
route add -net 106.102.0.96/27 gw 11.100.2.254


/sbin/sysctl -w net.ipv4.ip_forward=1
