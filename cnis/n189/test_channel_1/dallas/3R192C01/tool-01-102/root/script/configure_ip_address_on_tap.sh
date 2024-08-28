#!/usr/bin/env bash

BE_NIC=em4
DPDK_NIC1=p1p1
DPDK_NIC2=p3p1

ifconfig $BE_NIC up

ip link delete vlan1202 || true
ip link delete vlan1207 || true
ip link delete vlan1204 || true
ip link delete vlan1224 || true
ip link delete vlan1205 || true
ip link delete vlan1225 || true

ip link add link $BE_NIC name vlan1202 type vlan id 1202
ip link add link $BE_NIC name vlan1207 type vlan id 1207
ip link add link ${DPDK_NIC1}_tap name vlan1204 type vlan id 1204
ip link add link ${DPDK_NIC1}_tap name vlan1205 type vlan id 1205
ip link add link ${DPDK_NIC2}_tap name vlan1224 type vlan id 1224
ip link add link ${DPDK_NIC2}_tap name vlan1225 type vlan id 1225

ip addr add 172.30.16.102/24 dev vlan1202
ip addr add 172.30.49.102/24 dev vlan1207
ip addr add 172.30.48.102/24 dev vlan1204
ip addr add 172.30.50.102/24 dev vlan1224
ip addr add 172.30.64.102/24 dev vlan1205
ip addr add 172.30.66.102/24 dev vlan1225


ip -6 addr add fdac:30:64::102/64 dev vlan1205
ip -6 addr add fdac:30:66::102/64 dev vlan1225

ip link set vlan1202 up
ip link set vlan1207 up
ip link set vlan1204 up
ip link set vlan1224 up
ip link set vlan1205 up
ip link set vlan1225 up

ip route add 172.16.64.0/24 via 172.30.49.1 dev vlan1207
ip route add 172.16.72.0/24 via 172.30.49.1 dev vlan1207
ip route add 172.17.128.0/24 via 172.30.16.1 dev vlan1202
ip route add 172.17.128.6 via 172.30.16.1 dev vlan1202
ip route add 172.21.160.0/24 via 172.30.16.1 dev vlan1202

# amf n2/s1
ip route add 172.16.64.1/32 via 172.30.49.1 || true
ip route add 172.16.64.3/32 via 172.30.49.1 || true
ip route add 172.16.64.2/32 via 172.30.49.1 || true
ip route add 172.16.64.4/32 via 172.30.49.1 || true

