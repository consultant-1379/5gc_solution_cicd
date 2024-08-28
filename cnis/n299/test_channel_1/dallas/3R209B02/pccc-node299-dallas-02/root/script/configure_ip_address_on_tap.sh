#!/bin/bash

del_vlan () {
    echo $n "  deleting vlan interfaces ... "
    vlans=`/sbin/ip link | grep -E -o "vlan[[:digit:]]+"`
    for vlan in $vlans ; do
        /sbin/ip link set $vlan down
        /sbin/ip link delete $vlan
    done
    echo "done"
} # end of del_vlan

del_dallas_ip_rules () {
    echo $n "  deleting ip rules ... "
    /sbin/ip rule show | egrep 'lookup [0-9]' | awk -F"from" '{print "ip rule del from " $2 | "bash" }' >/dev/null
    /sbin/ip -6 rule show | egrep 'lookup [0-9]' | awk -F"from" '{print "ip -6 rule del from " $2 | "bash" }' >/dev/null

    echo "done"
} # end of del_dallas_ip_rules

interface_is_up() {
    local isup
    isup=$(ip addr show $1 up 2> /dev/null | grep 'UP')
    if [ $? -eq 0 ]; then
        echo "1"
    else
        echo "0"
    fi
}

interfaces_check() {

    # Put interface names in hosts inventory file. Defaults to p1p1 and p1p3
    NIC1=p1p1
    NIC2=p3p1
    local interface1_up
    local interface2_up
    local tap1_up
    local tap2_up
    interface1_up=$(interface_is_up $NIC1)
    interface2_up=$(interface_is_up $NIC2)
    tap1_up=$(interface_is_up ${NIC1}_tap)
    tap2_up=$(interface_is_up ${NIC2}_tap)

    if [[ $tap1_up -eq 1 && $tap2_up -eq 1 ]]; then
        INTERFACE1=${NIC1}_tap
        INTERFACE2=${NIC2}_tap
    elif [[ $interface1_up -eq 1 && $interface2_up -eq 1 ]]; then
        INTERFACE1=${NIC1}
        INTERFACE2=${NIC2}
    else
        echo "Not all interfaces are up"
        exit
    fi

} # end of interfaces_check
#################################################################

del_vlan
del_dallas_ip_rules

interfaces_check

#########################################
### Creating Dallas Interface address ###
#########################################
echo "<--------------------------------------->"
echo "--> media_cn"
ip link add link $INTERFACE1 name vlan1201 type vlan id 1201
ip link set vlan1201 up
ip addr add 172.30.0.102/24 dev vlan1201

ip link add link $INTERFACE2 name vlan1221 type vlan id 1221
ip link set vlan1221 up
ip addr add 172.30.2.102/24 dev vlan1221
echo "<--------------------------------------->"
echo "--> sig_cn"
ip link add link $INTERFACE1 name vlan1202 type vlan id 1202
ip link set vlan1202 up
ip addr add 172.30.16.102/24 dev vlan1202

ip link add link $INTERFACE2 name vlan1222 type vlan id 1222
ip link set vlan1222 up
ip addr add 172.30.18.102/24 dev vlan1222
echo "<--------------------------------------->"
echo "--> om_cn"
ip link add link $INTERFACE1 name vlan1203 type vlan id 1203
ip link set vlan1203 up
ip addr add 172.30.32.102/24 dev vlan1203

ip link add link $INTERFACE2 name vlan1223 type vlan id 1223
ip link set vlan1223 up
ip addr add 172.30.34.102/24 dev vlan1223
echo "<--------------------------------------->"
echo "--> ran"
ip link add link $INTERFACE1 name vlan1204 type vlan id 1204
ip link set vlan1204 up
ip addr add 172.30.48.102/24 dev vlan1204

ip link add link $INTERFACE2 name vlan1224 type vlan id 1224
ip link set vlan1224 up
ip addr add 172.30.50.102/24 dev vlan1224
echo "<--------------------------------------->"
echo "--> toext_open_1"
ip link add link $INTERFACE1 name vlan1205 type vlan id 1205
ip link set vlan1205 up
ip addr add 172.30.64.102/24 dev vlan1205

ip link add link $INTERFACE2 name vlan1225 type vlan id 1225
ip link set vlan1225 up
ip addr add 172.30.66.102/24 dev vlan1225
echo "<--------------------------------------->"
echo "--> toext_open_2"
ip link add link $INTERFACE1 name vlan1206 type vlan id 1206
ip link set vlan1206 up
ip addr add 172.30.80.102/24 dev vlan1206

ip link add link $INTERFACE2 name vlan1226 type vlan id 1226
ip link set vlan1226 up
ip addr add 172.30.82.102/24 dev vlan1226
echo "<--------------------------------------->"

#########################################
### Creating dallas static routes and ###
### IPs for simulators for outline    ###
#########################################
#####################################
### > media_cn
### < media_cn
#####################################
### > sig_cn
### < sig_cn
#####################################
### > om_cn
### < om_cn
#####################################
### > ran
###### > enb_s1mme_ip_addresses
######## > IPv4
ip route add 172.16.64.0/24 via 172.30.48.1 dev vlan1204
ip route add 172.16.64.0/24 via 172.30.48.1 dev vlan1204 table 1204
ip rule add from 8.128.32.0/20 table 1204

ip route add 172.16.64.0/24 via 172.30.50.1 dev vlan1224
ip route add 172.16.64.0/24 via 172.30.50.1 dev vlan1224 table 1224
ip rule add from 8.128.48.0/20 table 1224
ip route add 172.16.70.0/24 via 172.30.48.1 dev vlan1204
ip route add 172.16.70.0/24 via 172.30.48.1 dev vlan1204 table 1204
ip rule add from 8.128.32.0/20 table 1204

ip route add 172.16.70.0/24 via 172.30.50.1 dev vlan1224
ip route add 172.16.70.0/24 via 172.30.50.1 dev vlan1224 table 1224
ip rule add from 8.128.48.0/20 table 1224
######## < IPv4
######## > IPv6
######## < IPv6
###### < enb_s1mme_ip_addresses
###### > enb_s1u_ip_addresses
######## > IPv4
ip route add 172.18.64.0/24 via 172.30.48.1 dev vlan1204
ip route add 172.18.64.0/24 via 172.30.48.1 dev vlan1204 table 1204
ip rule add from 8.132.32.0/20 table 1204

ip route add 172.18.64.0/24 via 172.30.50.1 dev vlan1224
ip route add 172.18.64.0/24 via 172.30.50.1 dev vlan1224 table 1224
ip rule add from 8.132.48.0/20 table 1224
ip route add 172.18.70.0/24 via 172.30.48.1 dev vlan1204
ip route add 172.18.70.0/24 via 172.30.48.1 dev vlan1204 table 1204
ip rule add from 8.132.32.0/20 table 1204

ip route add 172.18.70.0/24 via 172.30.50.1 dev vlan1224
ip route add 172.18.70.0/24 via 172.30.50.1 dev vlan1224 table 1224
ip rule add from 8.132.48.0/20 table 1224
######## < IPv4
######## > IPv6
######## < IPv6
###### < enb_s1u_ip_addresses
###### > gnb_n3_ip_addresses
######## > IPv4
ip route add 172.18.64.0/24 via 172.30.48.1 dev vlan1204
ip route add 172.18.64.0/24 via 172.30.48.1 dev vlan1204 table 1204
ip rule add from 8.140.32.0/20 table 1204

ip route add 172.18.64.0/24 via 172.30.50.1 dev vlan1224
ip route add 172.18.64.0/24 via 172.30.50.1 dev vlan1224 table 1224
ip rule add from 8.140.48.0/20 table 1224
ip route add 172.18.70.0/24 via 172.30.48.1 dev vlan1204
ip route add 172.18.70.0/24 via 172.30.48.1 dev vlan1204 table 1204
ip rule add from 8.140.32.0/20 table 1204

ip route add 172.18.70.0/24 via 172.30.50.1 dev vlan1224
ip route add 172.18.70.0/24 via 172.30.50.1 dev vlan1224 table 1224
ip rule add from 8.140.48.0/20 table 1224
######## < IPv4
######## > IPv6
######## < IPv6
###### < gnb_n3_ip_addresses
###### > gnb_n2_ip_addresses
######## > IPv4
ip route add 172.16.64.0/24 via 172.30.48.1 dev vlan1204
ip route add 172.16.64.0/24 via 172.30.48.1 dev vlan1204 table 1204
ip rule add from 8.136.32.0/20 table 1204

ip route add 172.16.64.0/24 via 172.30.50.1 dev vlan1224
ip route add 172.16.64.0/24 via 172.30.50.1 dev vlan1224 table 1224
ip rule add from 8.136.48.0/20 table 1224
ip route add 172.16.70.0/24 via 172.30.48.1 dev vlan1204
ip route add 172.16.70.0/24 via 172.30.48.1 dev vlan1204 table 1204
ip rule add from 8.136.32.0/20 table 1204

ip route add 172.16.70.0/24 via 172.30.50.1 dev vlan1224
ip route add 172.16.70.0/24 via 172.30.50.1 dev vlan1224 table 1224
ip rule add from 8.136.48.0/20 table 1224
######## < IPv4
######## > IPv6
######## < IPv6
###### < gnb_n2_ip_addresses
### < ran
#####################################
### > toext_open_1
###### > gi_ip_addresses
######## > IPv4
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 193.8.0.0/14 table 1205

ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 193.12.0.0/14 table 1225
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 193.8.0.0/14 table 1205

ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 193.12.0.0/14 table 1225
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 193.8.0.0/14 table 1205

ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225
ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 193.12.0.0/14 table 1225
######## < IPv4
######## > IPv6
######## < IPv6
###### < gi_ip_addresses
###### > gi_net_1
######## > IPv4
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 194.8.0.0/14 table 1205

ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 194.12.0.0/14 table 1225
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 194.8.0.0/14 table 1205

ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 194.12.0.0/14 table 1225
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 194.8.0.0/14 table 1205

ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225
ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 194.12.0.0/14 table 1225
######## < IPv4
######## > IPv6
######## < IPv6
###### < gi_net_1
###### > gi_net_2
######## > IPv4
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 195.8.0.0/14 table 1205

ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 195.12.0.0/14 table 1225
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 195.8.0.0/14 table 1205

ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 195.12.0.0/14 table 1225
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 195.8.0.0/14 table 1205

ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225
ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 195.12.0.0/14 table 1225
######## < IPv4
######## > IPv6
######## < IPv6
###### < gi_net_2
###### > gi_net_3
######## > IPv4
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 196.8.0.0/14 table 1205

ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 196.12.0.0/14 table 1225
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 196.8.0.0/14 table 1205

ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 196.12.0.0/14 table 1225
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 196.8.0.0/14 table 1205

ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225
ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 196.12.0.0/14 table 1225
######## < IPv4
######## > IPv6
######## < IPv6
###### < gi_net_3
###### > gi_net_4
######## > IPv4
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 197.8.0.0/14 table 1205

ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 197.12.0.0/14 table 1225
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 197.8.0.0/14 table 1205

ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 197.12.0.0/14 table 1225
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 197.8.0.0/14 table 1205

ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225
ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 197.12.0.0/14 table 1225
######## < IPv4
######## > IPv6
######## < IPv6
###### < gi_net_4
###### > gi_net_5
######## > IPv4
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 198.8.0.0/14 table 1205

ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 198.12.0.0/14 table 1225
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 198.8.0.0/14 table 1205

ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 198.12.0.0/14 table 1225
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 198.8.0.0/14 table 1205

ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225
ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 198.12.0.0/14 table 1225
######## < IPv4
######## > IPv6
######## < IPv6
###### < gi_net_5
###### > gi_net_6
######## > IPv4
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.0.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 199.8.0.0/14 table 1205

ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.0.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 199.12.0.0/14 table 1225
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205
ip route add 21.64.0.0/10 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 199.8.0.0/14 table 1205

ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225
ip route add 21.64.0.0/10 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 199.12.0.0/14 table 1225
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205
ip route add 22.0.0.0/16 via 172.30.64.1 dev vlan1205 table 1205
ip rule add from 199.8.0.0/14 table 1205

ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225
ip route add 22.0.0.0/16 via 172.30.66.1 dev vlan1225 table 1225
ip rule add from 199.12.0.0/14 table 1225
######## < IPv4
######## > IPv6
######## < IPv6
###### < gi_net_6
### < toext_open_1
#####################################
### > toext_open_2
### < toext_open_2
#########################################
### Tagged based routing              ###
#########################################



#####################################
### om_cn_nets
##### 214.13.236.128/26
ip route add 214.13.236.128/26 via 172.30.32.1 dev vlan1203
##### 10.221.124.0/27
ip route add 10.221.124.0/27 via 172.30.32.1 dev vlan1203
#####################################


#################################################################
# Special workaround for tool machines
modprobe=/sbin/modprobe
echo="eval echo"

# Following is not sure that we need these. /2012-01-11 ervjaos
# load modules used by all tool machines
${modprobe} ipv6
# needed due to a stupid race condition in 8021q
${modprobe} 8021q

# kernel settings for all tool machines
if [ -d /proc/sys/net/ipv4/route ]; then
    ${echo} "65536 > /proc/sys/net/ipv4/route/max_size"
fi
if [ -d /proc/sys/net/ipv6/route ]; then
    ${echo} "4096 > /proc/sys/net/ipv6/route/max_size"

    # disable the Ipv6 RA message handling for diameter issue
    ${echo} "0 > /proc/sys/net/ipv6/conf/default/accept_ra"
fi
if [ -d /proc/sys/fs ]; then
    ${echo} "13103195 > /proc/sys/fs/file-max"
fi
if [ -d /proc/sys/net/ipv4/conf/all ]; then
    ${echo} "2 > /proc/sys/net/ipv4/conf/all/arp_announce"
fi

# nw buffer sizes for outline
if [ -d /proc/sys/net/core ]; then
    echo $n -e "\ntuning networking buffer sizes ... "
    # these tunings have an unknown source, but have been
    # used in st since late 2006. it may just be a workaround
    # for a bug in outline's tcp socket handling.
    # reference: daniel boman, 2006-11-07:
    # "outline status -change the buffer size". mail to st.
    # According to Gunnar, jan 2012, it is good to have
    ${echo} "16777216 > /proc/sys/net/core/rmem_max"
    ${echo} "16777216 > /proc/sys/net/core/wmem_max"
    echo "  done"
fi
