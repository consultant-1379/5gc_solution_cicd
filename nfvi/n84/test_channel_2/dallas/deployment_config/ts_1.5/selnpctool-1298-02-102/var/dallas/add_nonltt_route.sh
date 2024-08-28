#!/bin/bash

ip link add link em3 name vlan0051  type vlan id 51 || true
ip add add 11.20.2.102/19 dev vlan0051 || true
ip link set vlan0051 up || true


ip link add link p1p2_tap name vlan0112  type vlan id 112 || true
ip link add link p1p1_tap name vlan0114  type vlan id 114 || true
ip link add link p1p1_tap name vlan0115  type vlan id 115 || true
ip link add link p1p2_tap name vlan0129  type vlan id 129 || true
ip link add link p1p2_tap name vlan0130  type vlan id 130 || true
ip add add 11.101.30.1/24 dev vlan0130 || true
ip add add 11.101.29.1/24 dev vlan0129 || true
ip add add 11.101.5.1/24 dev vlan0115 || true
ip add add 11.101.4.1/24 dev vlan0114 || true
ip add add 11.101.2.1/24 dev vlan0112 || true
ip link set vlan0112 up || true
ip link set vlan0114 up || true
ip link set vlan0115 up || true
ip link set vlan0129 up || true
ip link set vlan0130 up || true

# amf sbi
ip route add 29.1.64.125/29 via 11.101.2.254 || true

# amf n2
ip route add 10.132.128.101/32  via 11.101.4.254 || true
ip route add 10.132.144.101/32  via 11.101.4.254 || true

# s1-mme
ip route add 10.132.144.156/32 via 11.101.4.254 || true
ip route add 10.132.128.156/32 via 11.101.4.254 || true

# worker signaling interface, source IP of smf
ip route add 11.1.2.0/24 via 11.101.2.254 || true
ip route add 11.2.2.0/24 via 11.101.2.254 || true

# ECFE smf-pool
ip route add 5.8.0.0/13 via 11.101.2.254 || true


ip route add 6.193.0.0/19 via 11.20.2.102 || true
ip route add 6.197.0.0/19 via 11.20.2.102 || true
ip route add 6.193.32.0/19 via 11.20.2.102 || true
ip route add 6.197.32.0/19 via 11.20.2.102 || true

ip route add 8.141.0.0/19 via 11.20.2.102 || true
ip route add 8.141.32.0/19 via 11.20.2.102 || true
ip route add 106.102.0.85/32 via 11.101.2.254 || true
ip route add 106.102.0.117/32 via 11.101.2.254 || true

