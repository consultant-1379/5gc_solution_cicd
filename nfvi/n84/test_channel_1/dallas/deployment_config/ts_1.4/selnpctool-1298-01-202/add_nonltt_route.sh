#!/bin/bash

ip link add link em1 name vlan0051  type vlan id 51 || true
ip add add 11.20.1.202/19 dev vlan0051 || true
ip link set vlan0051 up || true


ip link add link p2p1_tap name vlan0102  type vlan id 102 || true
ip link add link p1p1_tap name vlan0104  type vlan id 104 || true
ip link add link p1p1_tap name vlan0105  type vlan id 105 || true
ip link add link p2p1_tap name vlan0129  type vlan id 129 || true
ip link add link p2p1_tap name vlan0130 type vlan id 130 || true
ip add add 11.0.30.2/24 dev vlan0130 || true
ip add add 2a00:11:0:30::4/64 dev vlan0130 || true
ip add add 11.0.29.2/24 dev vlan0129 || true
ip add add 11.0.5.2/24 dev vlan0105 || true
ip add add 2a00:11:0:5::4/64 dev vlan0105 || true
ip add add 11.0.4.2/24 dev vlan0104 || true
ip add add 11.0.2.2/24 dev vlan0102 || true
ip link set vlan0102 up || true
ip link set vlan0104 up || true
ip link set vlan0105 up || true
ip link set vlan0129 up || true
ip link set vlan0130 up || true

# amf sbi
ip route add 29.0.64.120/29 via 11.0.2.254 || true

# amf n2
ip route add 10.131.128.96/29  via 11.0.4.254 || true
ip route add 10.131.144.96/29  via 11.0.4.254 || true

# s1-mme
ip route add 10.131.144.136/29 via 11.0.4.254 || true
ip route add 10.131.128.136/29 via 11.0.4.254 || true

# worker signaling interface, source IP of smf
ip route add 11.1.2.0/24 via 11.0.2.254 || true
ip route add 11.2.2.0/24 via 11.0.2.254 || true

# ECFE smf-pool
ip route add 5.8.0.0/13 via 11.0.2.254 || true


ip route add 6.192.0.0/19 via 11.20.1.101 || true
ip route add 6.196.0.0/19 via 11.20.1.101 || true
ip route add 6.192.32.0/19 via 11.20.1.102 || true
ip route add 6.196.32.0/19 via 11.20.1.102 || true

ip route add 8.140.0.0/19 via 11.20.1.101 || true
ip route add 8.140.32.0/19 via 11.20.1.102 || true
ip route add 106.2.0.65/32 via 11.0.2.254 || true
ip route add 106.2.0.97/32 via 11.0.2.254 || true

