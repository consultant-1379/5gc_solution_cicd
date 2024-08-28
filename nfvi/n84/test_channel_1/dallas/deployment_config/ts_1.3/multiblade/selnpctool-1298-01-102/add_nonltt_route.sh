#!/bin/bash

ip link add link em1 name vlan0051  type vlan id 51
ip add add 11.20.1.102/19 dev vlan0051
ip link set vlan0051 up

ip link add link p1p1 name vlan0102  type vlan id 102
ip link add link p1p1 name vlan0104  type vlan id 104
ip link add link p2p1 name vlan0105  type vlan id 105
ip add add 11.0.5.4/24 dev vlan0105
ip add add 11.0.4.4/24 dev vlan0104
ip add add 11.0.2.4/24 dev vlan0102
ip link set vlan0102 up
ip link set vlan0104 up
ip link set vlan0105 up

# amf sbi
ip route add 29.0.64.120/30 via 11.0.2.254 || true

# amf n2
ip route add 10.131.128.96/30  via 11.0.4.254 || true
ip route add 10.131.144.96/30  via 11.0.4.254 || true

# worker signaling interface, source IP of smf
ip route add 11.1.2.0/24 via 11.0.2.254 || true
ip route add 11.3.2.0/24 via 11.0.2.254 || true



# ECFE smf-pool
ip route add 5.8.0.0/13 via 11.0.2.254 || true


