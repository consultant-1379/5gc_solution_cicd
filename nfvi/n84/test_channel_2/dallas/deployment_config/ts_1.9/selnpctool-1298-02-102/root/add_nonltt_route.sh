#!/bin/bash

# vlan 3715 for signaling
# vlan 3716 for ran
# vlan 3717 for sgi

ip link add link p1p1_tap name vlan3715  type vlan id 3715
ip link add link p1p2_tap name vlan3716  type vlan id 3716
ip link add link p1p1_tap name vlan3717  type vlan id 3717
ip add add 11.101.5.1/24 dev vlan3717
ip add add 11.101.4.1/24 dev vlan3716
ip add add 11.101.2.1/24 dev vlan3715
ip link set vlan3715 up
ip link set vlan3716 up
ip link set vlan3717 up

# 715 - amf sbi
#ip route add 29.0.64.125/30 via 11.101.2.254 || true

# 716 - amf n2
ip route add 10.131.128.101/32 via 11.101.4.254 || true
ip route add 10.131.144.101/32 via 11.101.4.254 || true



