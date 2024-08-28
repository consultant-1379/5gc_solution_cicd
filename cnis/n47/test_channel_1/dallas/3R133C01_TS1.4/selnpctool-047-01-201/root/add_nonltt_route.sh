#!/bin/bash

#  141   signaling
#  143   ran-1
#  153   ran-2
#  144   sgi1-1
#  154   sgi1-2

#ip link add link em1 name vlan0051  type vlan id 51 || true
#ip add add 11.20.1.201/19 dev vlan0051 ||true
#ip link set vlan0051 up ||true

ip link add link p1p1_tap name vlan0141  type vlan id 141 || true
ip link add link p1p1_tap name vlan0143  type vlan id 143 || true
ip link add link p1p1_tap name vlan0144  type vlan id 144 || true
ip link add link p3p1_tap name vlan0154  type vlan id 154 || true
ip link add link p3p1_tap name vlan0153  type vlan id 153 || true

ip add add 11.100.2.2/24 dev vlan0141 || true
ip add add 11.100.30.2/24 dev vlan0154 || true
#ip add add 2a00:11.100.30::1/64 dev vlan0154 || true
ip add add 11.100.29.2/24 dev vlan0153 || true
ip add add 11.100.5.2/24 dev vlan0144 || true
#ip add add 2a00:11.100.5::1/64 dev vlan0144 || true
ip add add 11.100.4.2/24 dev vlan0143 || true
ip link set vlan0153 up || true
ip link set vlan0154 up || true
ip link set vlan0143 up || true
ip link set vlan0144 up || true
ip link set vlan0141 up || true


# amf n2

route add -host 106.4.0.129/32 gw 11.100.4.1
route add -host 106.4.0.161/32 gw 11.100.29.1

#### GnodeB N2
route add -net 8.148.0.0/19 gw 11.20.1.101
route add -net 8.148.32.0/19 gw 11.20.1.102

### mme S1
route add -host 106.4.0.65/32 gw 11.100.4.1
route add -host 106.4.0.97/32 gw 11.100.29.1

#### EnodeB  S1C
route add -net 8.140.0.0/19 gw 11.20.1.101
route add -net 8.140.32.0/19 gw 11.20.1.102

##### MME  S6a
route add -host 106.2.0.65/32 gw 11.100.2.1
route add -host 106.2.0.97/32 gw 11.100.2.1


/sbin/sysctl -w net.ipv4.ip_forward=1

