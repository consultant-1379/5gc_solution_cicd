#!/bin/bash
### Adaptation to make the same script work on all hosts
### Change the INDEX_IP to host number (Starting on 2 for FE1, 3 for FE2, 4 for master, 5 for BE1 ...)
### Set RUN_OUTLINE = 1 to setup routing and interfaces for outline. Normally on dallas master
#INDEX_IP=4
INDEX_CHANNEL=1
INDEX_IP=2
RUN_OUTLINE=0
ADDITIONAL_NET=""
# MM_ROUTES=0
### End Adaptation
while getopts 'c:i:a:oh' opt; do
  case "$opt" in
    c)
      INDEX_CHANNEL=$OPTARG
      echo "Setting Channel index $INDEX_CHANNEL"
      ;;

    i)
      INDEX_IP=$OPTARG
      echo "Setting IP index $INDEX_IP"
      ;;

    o)
      RUN_OUTLINE=1
      echo "Setup Outline IPs"
      ;;
    a)
      # Additional om_cn routing. Added to allow callback to DNS from worker om_cn range.
      # POD specific so needed to be passed on from .hook.yaml
      ADDITIONAL_NET=$OPTARG
      ;;
   
    ?|h)
      echo "Usage: $(basename $0) [-c channel_index] [-i ip_index] [-o]"
      echo "   channel_index defaults to 1"
      echo "   ip_index defaults to 2. 1 is reserved for gateway."
      echo "   If -o option is set setup outline ips on host"
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"
add_om_cn_nets() {
   echo $1
   #for net in $(echo $1 sed 's/:/\n/'| awk -F":" '{for (n=0; n<NF ; n++) {print $n} }')
   for net in $(echo $1 |sed 's/:/\n/')
   do
     echo "ip route add $net via 11.100.3.1 dev vlan${INDEX_CHANNEL}42"
     ip route add $net via 11.100.3.1 dev vlan${INDEX_CHANNEL}42
   done
}

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
    /sbin/ip rule show | grep -Ev '^(0|32766|32767):' | awk -F : '{print "ip rule del " $2 | "bash" }' >/dev/null
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
    # This part shall be updated later when interface information can be fetched from Hydra
    # For now, /etc/testtool.interfaces.conf is used to find the dallas interface.
    # Currently allas interface is always 2 per blade.
    # In the future, 3rd interface could be added, and different SUT could use diffent interfaces
    # however it will be in 2021 or even later dream
    if [ -f "/etc/testtool.interfaces.conf" ]; then
       . "/etc/testtool.interfaces.conf"

        # decide which interface to use for vlan setup
        local interface1_up
        local interface2_up
        local tap1_up
        local tap2_up
        interface1_up=$(interface_is_up $INTERFACE_SWITCH1)
        interface2_up=$(interface_is_up $INTERFACE_SWITCH2)
        tap1_up=$(interface_is_up $NIC1_NAME_TAP)
        tap2_up=$(interface_is_up $NIC2_NAME_TAP)

        if [[ $tap1_up -eq 1 && $tap2_up -eq 1 ]]; then
            INTERFACE1=$NIC1_NAME_TAP
            INTERFACE2=$NIC2_NAME_TAP
        elif [[ $interface1_up -eq 1 && $interface2_up -eq 1 ]]; then
            INTERFACE1=$INTERFACE_SWITCH1
            INTERFACE2=$INTERFACE_SWITCH2
        else
            echo "Not all interfaces are up"
            exit
        fi
    fi

} # end of interfaces_check
#################################################################

del_vlan
del_dallas_ip_rules

interfaces_check

ip link add link $INTERFACE1 name vlan${INDEX_CHANNEL}40 type vlan id ${INDEX_CHANNEL}40
ip link set vlan${INDEX_CHANNEL}40 up
ip addr add 11.100.1.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}40
ip -6 addr add 2a11:100:1::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}40

ip link add link $INTERFACE1 name vlan${INDEX_CHANNEL}41 type vlan id ${INDEX_CHANNEL}41
ip link set vlan${INDEX_CHANNEL}41 up
ip addr add 11.100.2.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}41
ip -6 addr add 2a11:100:2::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}41

ip link add link $INTERFACE1 name vlan${INDEX_CHANNEL}42 type vlan id ${INDEX_CHANNEL}42
ip link set vlan${INDEX_CHANNEL}42 up
ip addr add 11.100.3.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}42
ip -6 addr add 2a11:100:3::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}42

ip link add link $INTERFACE1 name vlan${INDEX_CHANNEL}43 type vlan id ${INDEX_CHANNEL}43
ip link set vlan${INDEX_CHANNEL}43 up
ip addr add 11.100.4.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}43
ip -6 addr add 2a11:100:4::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}43

ip link add link $INTERFACE1 name vlan${INDEX_CHANNEL}44 type vlan id ${INDEX_CHANNEL}44
ip link set vlan${INDEX_CHANNEL}44 up
ip addr add 11.100.5.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}44
ip -6 addr add 2a11:100:5::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}44

# ip link add link $INTERFACE1 name vlan${INDEX_CHANNEL}45 type vlan id ${INDEX_CHANNEL}45
# ip link set vlan${INDEX_CHANNEL}45 up
# ip addr add 11.100.6.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}45
# ip -6 addr add 2a11:100:6::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}45

# ip link add link $INTERFACE1 name vlan${INDEX_CHANNEL}46 type vlan id ${INDEX_CHANNEL}46
# ip link set vlan${INDEX_CHANNEL}46 up
# ip addr add 11.100.7.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}46
# ip -6 addr add 2a11:100:7::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}46

# ip link add link $INTERFACE1 name vlan${INDEX_CHANNEL}47 type vlan id ${INDEX_CHANNEL}47
# ip link set vlan${INDEX_CHANNEL}47 up
# ip addr add 11.100.8.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}47
# ip -6 addr add 2a11:100:8::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}47

# ip link add link $INTERFACE1 name vlan${INDEX_CHANNEL}48 type vlan id ${INDEX_CHANNEL}48
# ip link set vlan${INDEX_CHANNEL}48 up
# ip addr add 11.100.9.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}48
# ip -6 addr add 2a11:100:9::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}48

ip link add link $INTERFACE2 name vlan${INDEX_CHANNEL}50 type vlan id ${INDEX_CHANNEL}50
ip link set vlan${INDEX_CHANNEL}50 up
ip addr add 11.100.26.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}50
ip -6 addr add 2a11:100:26::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}50

ip link add link $INTERFACE2 name vlan${INDEX_CHANNEL}51 type vlan id ${INDEX_CHANNEL}51
ip link set vlan${INDEX_CHANNEL}51 up
ip addr add 11.100.27.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}51
ip -6 addr add 2a11:100:27::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}51

ip link add link $INTERFACE2 name vlan${INDEX_CHANNEL}52 type vlan id ${INDEX_CHANNEL}52
ip link set vlan${INDEX_CHANNEL}52 up
ip addr add 11.100.28.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}52
ip -6 addr add 2a11:100:28::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}52

ip link add link $INTERFACE2 name vlan${INDEX_CHANNEL}53 type vlan id ${INDEX_CHANNEL}53
ip link set vlan${INDEX_CHANNEL}53 up
ip addr add 11.100.29.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}53
ip -6 addr add 2a11:100:29::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}53

ip link add link $INTERFACE2 name vlan${INDEX_CHANNEL}54 type vlan id ${INDEX_CHANNEL}54
ip link set vlan${INDEX_CHANNEL}54 up
ip addr add 11.100.30.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}54
ip -6 addr add 2a11:100:30::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}54

# ip link add link $INTERFACE2 name vlan${INDEX_CHANNEL}55 type vlan id ${INDEX_CHANNEL}55
# ip link set vlan${INDEX_CHANNEL}55 up
# ip addr add 11.100.31.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}55
# ip -6 addr add 2a11:100:31::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}55

# ip link add link $INTERFACE2 name vlan${INDEX_CHANNEL}56 type vlan id ${INDEX_CHANNEL}56
# ip link set vlan${INDEX_CHANNEL}56 up
# ip addr add 11.100.32.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}56
# ip -6 addr add 2a11:100:32::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}56

# ip link add link $INTERFACE2 name vlan${INDEX_CHANNEL}57 type vlan id ${INDEX_CHANNEL}57
# ip link set vlan${INDEX_CHANNEL}57 up
# ip addr add 11.100.33.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}57
# ip -6 addr add 2a11:100:33::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}57

# ip link add link $INTERFACE2 name vlan${INDEX_CHANNEL}58 type vlan id ${INDEX_CHANNEL}58
# ip link set vlan${INDEX_CHANNEL}58 up
# ip addr add 11.100.34.${INDEX_IP}/24 dev vlan${INDEX_CHANNEL}58
# ip -6 addr add 2a11:100:34::${INDEX_IP}/64 dev vlan${INDEX_CHANNEL}58

#####################################
### Creating dallas static routes ###
#####################################

### MEDIA
ip route add 107.1.0.0/16 via 11.100.1.1 dev vlan${INDEX_CHANNEL}40 ### Service Nets - SM - Media
ip route add 107.1.0.0/16 via 11.100.1.1 dev vlan${INDEX_CHANNEL}40 table 11       ### Service Nets - SM - Media
ip -6 route add 2a00:107:1::/48 via 2a11:100:1::1 dev vlan${INDEX_CHANNEL}40
ip -6 route add 2a00:107:1::/48 via 2a11:100:1::1 dev vlan${INDEX_CHANNEL}40 table 11
ip route add 107.1.0.0/16 via 11.100.26.1 dev vlan${INDEX_CHANNEL}50 table 12    ### Service Nets - SM - Media
ip -6 route add 2a00:107:1::/48 via 2a11:100:26::1 dev vlan${INDEX_CHANNEL}50 table 12

ip route add 106.1.0.0/16 via 11.100.1.1 dev vlan${INDEX_CHANNEL}40 ### Service Nets - MM - Media
ip route add 106.1.0.0/16 via 11.100.1.1 dev vlan${INDEX_CHANNEL}40 table 11       ### Service Nets - MM - Media
ip -6 route add 2a00:106:1::/48 via 2a11:100:1::1 dev vlan${INDEX_CHANNEL}40
ip -6 route add 2a00:106:1::/48 via 2a11:100:1::1 dev vlan${INDEX_CHANNEL}40 table 11
ip route add 106.1.0.0/16 via 11.100.26.1 dev vlan${INDEX_CHANNEL}50 table 12    ### Service Nets - MM - Media
ip -6 route add 2a00:106:1::/48 via 2a11:100:26::1 dev vlan${INDEX_CHANNEL}50 table 12

### SIGNALING
ip route add 107.2.0.0/16 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41 ### Service Nets - SM
ip route add 107.2.0.0/16 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41 table 21  ### Service Nets - SM
ip -6 route add 2a00:107:2::/48 via 2a11:100:2::1 dev vlan${INDEX_CHANNEL}41
ip -6 route add 2a00:107:2::/48 via 2a11:100:2::1 dev vlan${INDEX_CHANNEL}41 table 21
ip route add 107.2.0.0/16 via 11.100.27.1 dev vlan${INDEX_CHANNEL}51 table 22  ### Service Nets - SM
ip -6 route add 2a00:107:2::/48 via 2a11:100:27::1 dev vlan${INDEX_CHANNEL}51 table 22

ip route add 107.9.0.0/16 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41 ### Service Nets - SM
ip route add 107.9.0.0/16 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41 table 21  ### Service Nets - SM
ip -6 route add 2a00:107:9::/48 via 2a11:100:2::1 dev vlan${INDEX_CHANNEL}41
ip -6 route add 2a00:107:9::/48 via 2a11:100:2::1 dev vlan${INDEX_CHANNEL}41 table 21
ip route add 107.9.0.0/16 via 11.100.27.1 dev vlan${INDEX_CHANNEL}51 table 22  ### Service Nets - SM
ip -6 route add 2a00:107:9::/48 via 2a11:100:27::1 dev vlan${INDEX_CHANNEL}51 table 22

ip route add 105.2.0.0/16 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41  ### Service Nets - ADP
ip -6 route add 2a00:105:2::/48 via 2a11:100:2::1 dev vlan${INDEX_CHANNEL}41

ip route add 192.168.2.0/24 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41 ### ECFE for MESOS (To be obsolete after PCTSIMBAD-921)
ip route add 11.110.2.0/24 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41  ### ECFE
ip route add 11.110.102.0/24 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41  ### ECFE Geored site 2

ip route add 108.2.0.0/16 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41 ### Service Nets - PCG
ip route add 108.2.0.0/16 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41 table 21  ### Service Nets - PCG
ip -6 route add 2a00:108:2::/48 via 2a11:100:2::1 dev vlan${INDEX_CHANNEL}41
ip -6 route add 2a00:108:2::/48 via 2a11:100:2::1 dev vlan${INDEX_CHANNEL}41 table 21

ip route add 108.2.0.0/16 via 11.100.27.1 dev vlan${INDEX_CHANNEL}51 table 22  ### Service Nets - PCG
ip -6 route add 2a00:108:2::/48 via 2a11:100:27::1 dev vlan${INDEX_CHANNEL}51 table 22

ip route add 106.2.0.0/16 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41 ### Service Nets - MM
ip route add 106.2.0.0/16 via 11.100.2.1 dev vlan${INDEX_CHANNEL}41 table 21  ### Service Nets - MM
ip -6 route add 2a00:106:2::/48 via 2a11:100:2::1 dev vlan${INDEX_CHANNEL}41
ip -6 route add 2a00:106:2::/48 via 2a11:100:2::1 dev vlan${INDEX_CHANNEL}41 table 21

ip route add 106.2.0.0/16 via 11.100.27.1 dev vlan${INDEX_CHANNEL}51 table 22  ### Service Nets - MM
ip -6 route add 2a00:106:2::/48 via 2a11:100:27::1 dev vlan${INDEX_CHANNEL}51 table 22

# PCLABS-5865: workaround until this ticket is solved
# Current address range "8.94.x.x" is for dallas s11 address in media context
# Address shall be replaced by dedicated one in signaling context when ticket is solved
# Routes are needed between outline and all dallas hosts, currently up to 4 hosts are hardcoded.
ip route add 8.94.32.0/19 dev vlan${INDEX_CHANNEL}41  # Service Nets - Dallas dmme (Dallas - Outline communication)
ip route add 8.94.64.0/19 dev vlan${INDEX_CHANNEL}41  # Service Nets - Dallas dmme (Dallas - Outline communication)
ip route add 8.94.96.0/19 dev vlan${INDEX_CHANNEL}41  # Service Nets - Dallas dmme (Dallas - Outline communication)


### OM_CN
ip route add 107.3.0.0/16 via 11.100.3.1 dev vlan${INDEX_CHANNEL}42 ### Service Nets - OM_CN
ip route add 107.3.0.0/16 via 11.100.3.1 dev vlan${INDEX_CHANNEL}42 table 31  ### Service Nets - OM_CN
ip -6 route add 2a00:107:3::/48 via 2a11:100:3::1 dev vlan${INDEX_CHANNEL}42
ip -6 route add 2a00:107:3::/48 via 2a11:100:3::1 dev vlan${INDEX_CHANNEL}42 table 31
ip route add 107.3.0.0/16 via 11.100.28.1 dev vlan${INDEX_CHANNEL}52 table 32  ### Service Nets - OM_CN
ip -6 route add 2a00:107:3::/48 via 2a11:100:28::1 dev vlan${INDEX_CHANNEL}52 table 32

ip route add 106.3.0.0/16 via 11.100.3.1 dev vlan${INDEX_CHANNEL}42 ### Service Nets - OM_CN MM
ip route add 106.3.0.0/16 via 11.100.3.1 dev vlan${INDEX_CHANNEL}42 table 31  ### Service Nets - OM_CN MM
ip -6 route add 2a00:106:3::/48 via 2a11:100:3::1 dev vlan${INDEX_CHANNEL}42
ip -6 route add 2a00:106:3::/48 via 2a11:100:3::1 dev vlan${INDEX_CHANNEL}42 table 31
ip route add 106.3.0.0/16 via 11.100.28.1 dev vlan${INDEX_CHANNEL}52 table 32  ### Service Nets - OM_CN MM
ip -6 route add 2a00:106:3::/48 via 2a11:100:28::1 dev vlan${INDEX_CHANNEL}52 table 32


ip route add 110.3.0.0/16 via 11.100.3.1 dev vlan${INDEX_CHANNEL}42  ### Service Nets - ADP
ip -6 route add 2a00:110:3::/48 via 2a11:100:3::1 dev vlan${INDEX_CHANNEL}42

if [ "${ADDITIONAL_NET}" != "" ]
then
    add_om_cn_nets $ADDITIONAL_NET
    #ip route add $ADDITIONAL_NET via 11.100.3.1 dev vlan${INDEX_CHANNEL}42 # Routing for ccd_ecfe_om DNS traffic
fi

### RAN
ip route add 108.4.0.0/16 via 11.100.4.1 dev vlan${INDEX_CHANNEL}43  ### Service Nets - RAN
ip route add 108.4.0.0/16 via 11.100.4.1 dev vlan${INDEX_CHANNEL}43 table 41  ### Service Nets - RAN
ip -6 route add 2a00:108:4::/48 via 2a11:100:4::1 dev vlan${INDEX_CHANNEL}43
ip -6 route add 2a00:108:4::/48 via 2a11:100:4::1 dev vlan${INDEX_CHANNEL}43 table 41

ip route add 108.4.0.0/16 via 11.100.29.1 dev vlan${INDEX_CHANNEL}53
ip route add 108.4.0.0/16 via 11.100.29.1 dev vlan${INDEX_CHANNEL}53 table 42  ### Service Nets - RAN
ip -6 route add 2a00:108:4::/48 via 2a11:100:29::1 dev vlan${INDEX_CHANNEL}53
ip -6 route add 2a00:108:4::/48 via 2a11:100:29::1 dev vlan${INDEX_CHANNEL}53 table 42

ip route add 106.4.0.0/16 via 11.100.4.1 dev vlan${INDEX_CHANNEL}43
ip route add 106.4.0.0/16 via 11.100.4.1 dev vlan${INDEX_CHANNEL}43 table 41  ### Service Nets - RAN MM
ip -6 route add 2a00:106:4::/48 via 2a11:100:4::1 dev vlan${INDEX_CHANNEL}43
ip -6 route add 2a00:106:4::/48 via 2a11:100:4::1 dev vlan${INDEX_CHANNEL}43 table 41

ip route add 106.4.0.0/16 via 11.100.29.1 dev vlan${INDEX_CHANNEL}53
ip route add 106.4.0.0/16 via 11.100.29.1 dev vlan${INDEX_CHANNEL}53 table 42  ### Service Nets - RAN MM
ip -6 route add 2a00:106:4::/48 via 2a11:100:29::1 dev vlan${INDEX_CHANNEL}53
ip -6 route add 2a00:106:4::/48 via 2a11:100:29::1 dev vlan${INDEX_CHANNEL}53 table 42
### RAN

### SGI1
ip route add 16.0.0.0/5 via 11.100.5.1 dev vlan${INDEX_CHANNEL}44 table 51
ip -6 route add 2A01:0001::/32 via 2a11:100:5::1 dev vlan${INDEX_CHANNEL}44 table 51
ip route add 16.0.0.0/5 via 11.100.30.1 dev vlan${INDEX_CHANNEL}54 table 52
ip -6 route add 2A01:0001::/32 via 2a11:100:30::1 dev vlan${INDEX_CHANNEL}54 table 52

### SGI address 192.0.0.0, 192.4.0.0, etc needs to be added when Hydra assigns ip addreess.

### SGI2
ip route add 24.0.0.0/5 via 11.100.6.1 dev vlan${INDEX_CHANNEL}45 table 51
ip -6 route add 2A01:0002::/32 via 2a11:100:6::1 dev vlan${INDEX_CHANNEL}45 table 51
ip route add 24.0.0.0/5 via 11.100.31.1 dev vlan${INDEX_CHANNEL}55 table 52
ip -6 route add 2A01:0002::/32 via 2a11:100:31::1 dev vlan${INDEX_CHANNEL}55 table 52

### SGI3
ip route add 32.0.0.0/5 via 11.100.7.1 dev vlan${INDEX_CHANNEL}46 table 51
ip -6 route add 2A01:0003::/32 via 2a11:100:7::1 dev vlan${INDEX_CHANNEL}46 table 51
ip route add 32.0.0.0/5 via 11.100.32.1 dev vlan${INDEX_CHANNEL}56 table 52
ip -6 route add 2A01:0003::/32 via 2a11:100:32::1 dev vlan${INDEX_CHANNEL}56 table 52

### SGI4
ip route add 40.0.0.0/5 via 11.100.8.1 dev vlan${INDEX_CHANNEL}47 table 51
ip -6 route add 2A01:0004::/32 via 2a11:100:8::1 dev vlan${INDEX_CHANNEL}47 table 51
ip route add 40.0.0.0/5 via 11.100.33.1 dev vlan${INDEX_CHANNEL}57 table 52
ip -6 route add 2A01:0004::/32 via 2a11:100:33::1 dev vlan${INDEX_CHANNEL}57 table 52

### SGI5
ip route add 48.0.0.0/5 via 11.100.9.1 dev vlan${INDEX_CHANNEL}48 table 51
ip -6 route add 2A01:0005::/32 via 2a11:100:9::1 dev vlan${INDEX_CHANNEL}48 table 51
ip route add 48.0.0.0/5 via 11.100.34.1 dev vlan${INDEX_CHANNEL}58 table 52
ip -6 route add 2A01:0005::/32 via 2a11:100:34::1 dev vlan${INDEX_CHANNEL}58 table 52



################################
### Add Dallas rules ###
################################

ip rule add from 8.0.0.0/20 table 21
ip rule add from 8.0.16.0/20 table 22
ip rule add from 8.2.0.0/20 table 21
ip rule add from 8.2.16.0/20 table 22
ip rule add from 8.4.0.0/20 table 21
ip rule add from 8.4.16.0/20 table 22
ip rule add from 8.6.0.0/20 table 21
ip rule add from 8.6.16.0/20 table 22
ip rule add from 8.8.0.0/20 table 21
ip rule add from 8.8.16.0/20 table 22

ip rule add from 8.10.0.0/20 table 21
ip rule add from 8.10.16.0/20 table 22
ip rule add from 8.12.0.0/20 table 21
ip rule add from 8.12.16.0/20 table 22
ip rule add from 8.14.0.0/20 table 21
ip rule add from 8.14.16.0/20 table 22
ip rule add from 8.16.0.0/20 table 21
ip rule add from 8.16.16.0/20 table 22
ip rule add from 8.18.0.0/20 table 21
ip rule add from 8.18.16.0/20 table 22

ip rule add from 8.20.0.0/20 table 21
ip rule add from 8.20.16.0/20 table 22
ip rule add from 8.22.0.0/20 table 21
ip rule add from 8.22.16.0/20 table 22
ip rule add from 8.24.0.0/20 table 21
ip rule add from 8.24.16.0/20 table 22
ip rule add from 8.26.0.0/20 table 21
ip rule add from 8.26.16.0/20 table 22
ip rule add from 8.28.0.0/20 table 21
ip rule add from 8.28.16.0/20 table 22

ip rule add from 8.30.0.0/20 table 21
ip rule add from 8.30.16.0/20 table 22
ip rule add from 8.32.0.0/20 table 21
ip rule add from 8.32.16.0/20 table 22
ip rule add from 8.34.0.0/20 table 21
ip rule add from 8.34.16.0/20 table 22
ip rule add from 8.36.0.0/20 table 21
ip rule add from 8.36.16.0/20 table 22
ip rule add from 8.38.0.0/20 table 21
ip rule add from 8.38.16.0/20 table 22

ip rule add from 8.40.0.0/20 table 21
ip rule add from 8.40.16.0/20 table 22
ip rule add from 8.42.0.0/20 table 21
ip rule add from 8.42.16.0/20 table 22
ip rule add from 8.44.0.0/20 table 21
ip rule add from 8.44.16.0/20 table 22
ip rule add from 8.46.0.0/20 table 21
ip rule add from 8.46.16.0/20 table 22
ip rule add from 8.46.32.0/20 table 21
ip rule add from 8.46.48.0/20 table 22
ip rule add from 8.46.64.0/20 table 21
ip rule add from 8.46.80.0/20 table 22
ip rule add from 8.46.96.0/20 table 21
ip rule add from 8.46.112.0/20 table 22
ip rule add from 8.48.0.0/20 table 21
ip rule add from 8.48.16.0/20 table 22
ip rule add from 8.48.32.0/20 table 21
ip rule add from 8.48.48.0/20 table 22
ip rule add from 8.48.64.0/20 table 21
ip rule add from 8.48.80.0/20 table 22
ip rule add from 8.48.96.0/20 table 21
ip rule add from 8.48.112.0/20 table 22

ip rule add from 8.50.0.0/20 table 21
ip rule add from 8.50.16.0/20 table 22
ip rule add from 8.52.0.0/20 table 21
ip rule add from 8.52.16.0/20 table 22
ip rule add from 8.54.0.0/20 table 21
ip rule add from 8.54.16.0/20 table 22
ip rule add from 8.56.0.0/20 table 21
ip rule add from 8.56.16.0/20 table 22
ip rule add from 8.58.0.0/20 table 21
ip rule add from 8.58.16.0/20 table 22

ip rule add from 8.60.0.0/20 table 21
ip rule add from 8.60.16.0/20 table 22
ip rule add from 8.60.32.0/20 table 21
ip rule add from 8.60.48.0/20 table 22
ip rule add from 8.60.64.0/20 table 21
ip rule add from 8.60.80.0/20 table 22
ip rule add from 8.60.96.0/20 table 21
ip rule add from 8.60.112.0/20 table 22
ip rule add from 8.62.0.0/20 table 21
ip rule add from 8.62.16.0/20 table 22
ip rule add from 8.64.0.0/20 table 21
ip rule add from 8.64.16.0/20 table 22
ip rule add from 8.66.0.0/20 table 21
ip rule add from 8.66.16.0/20 table 22
ip rule add from 8.66.32.0/20 table 21
ip rule add from 8.66.48.0/20 table 22
ip rule add from 8.66.64.0/20 table 21
ip rule add from 8.66.80.0/20 table 22
ip rule add from 8.66.96.0/20 table 21
ip rule add from 8.66.112.0/20 table 22
ip rule add from 8.68.0.0/20 table 21
ip rule add from 8.68.16.0/20 table 22

ip rule add from 8.70.0.0/20 table 21
ip rule add from 8.70.16.0/20 table 22
ip rule add from 8.72.0.0/20 table 21
ip rule add from 8.72.16.0/20 table 22
ip rule add from 8.74.0.0/20 table 21
ip rule add from 8.74.16.0/20 table 22
ip rule add from 8.76.0.0/20 table 11
ip rule add from 8.76.16.0/20 table 12
ip rule add from 8.78.0.0/20 table 21
ip rule add from 8.78.16.0/20 table 22

ip rule add from 8.80.0.0/20 table 11
ip rule add from 8.80.16.0/20 table 12
ip rule add from 8.82.0.0/20 table 21
ip rule add from 8.82.16.0/20 table 22
ip rule add from 8.84.0.0/20 table 21
ip rule add from 8.84.16.0/20 table 22
ip rule add from 8.86.0.0/20 table 11
ip rule add from 8.86.16.0/20 table 12
ip rule add from 8.88.0.0/20 table 11
ip rule add from 8.88.16.0/20 table 12

ip rule add from 8.90.0.0/20 table 11
ip rule add from 8.90.16.0/20 table 12
ip rule add from 8.92.0.0/20 table 11
ip rule add from 8.92.16.0/20 table 12
ip rule add from 8.94.0.0/20 table 11
ip rule add from 8.94.16.0/20 table 12
ip rule add from 8.94.32.0/20 table 11
ip rule add from 8.94.48.0/20 table 12
ip rule add from 8.94.64.0/20 table 11
ip rule add from 8.94.80.0/20 table 12
ip rule add from 8.94.96.0/20 table 11
ip rule add from 8.94.112.0/20 table 12

ip rule add from 8.96.0.0/20 table 11
ip rule add from 8.96.16.0/20 table 12
ip rule add from 8.98.0.0/20 table 11
ip rule add from 8.98.16.0/20 table 12

ip rule add from 8.100.0.0/20 table 11
ip rule add from 8.100.16.0/20 table 12
ip rule add from 8.102.0.0/20 table 11
ip rule add from 8.102.16.0/20 table 12
ip rule add from 8.104.0.0/20 table 41
ip rule add from 8.104.16.0/20 table 42
ip rule add from 8.106.0.0/20 table 11
ip rule add from 8.106.16.0/20 table 12
ip rule add from 8.108.0.0/20 table 11
ip rule add from 8.108.16.0/20 table 12
ip rule add from 8.108.32.0/20 table 11
ip rule add from 8.108.48.0/20 table 12
ip rule add from 8.108.64.0/20 table 11
ip rule add from 8.108.80.0/20 table 12
ip rule add from 8.108.96.0/20 table 11
ip rule add from 8.108.112.0/20 table 12

ip rule add from 8.110.0.0/20 table 11
ip rule add from 8.110.16.0/20 table 12
ip rule add from 8.112.0.0/20 table 11
ip rule add from 8.112.16.0/20 table 12
ip rule add from 8.114.0.0/20 table 11
ip rule add from 8.114.16.0/20 table 12
ip rule add from 8.116.0.0/20 table 11
ip rule add from 8.116.16.0/20 table 12
ip rule add from 8.118.0.0/20 table 11
ip rule add from 8.118.16.0/20 table 12

ip rule add from 8.120.0.0/20 table 11
ip rule add from 8.120.16.0/20 table 12
ip rule add from 8.122.0.0/20 table 11
ip rule add from 8.122.16.0/20 table 12
ip rule add from 8.124.0.0/20 table 31
ip rule add from 8.124.16.0/20 table 32
ip rule add from 8.126.0.0/20 table 31
ip rule add from 8.126.16.0/20 table 32
ip rule add from 8.128.0.0/20 table 31
ip rule add from 8.128.16.0/20 table 32

ip rule add from 8.130.0.0/20 table 41
ip rule add from 8.130.16.0/20 table 42
ip rule add from 8.132.0.0/20 table 41
ip rule add from 8.132.16.0/20 table 42
ip rule add from 8.134.0.0/20 table 41
ip rule add from 8.134.16.0/20 table 42
ip rule add from 8.136.0.0/20 table 41
ip rule add from 8.136.16.0/20 table 42
ip rule add from 8.138.0.0/20 table 41
ip rule add from 8.138.16.0/20 table 42

ip rule add from 8.140.0.0/19 table 41
ip rule add from 8.140.32.0/19 table 42
ip rule add from 8.140.64.0/19 table 41
ip rule add from 8.140.96.0/19 table 42
ip rule add from 8.140.128.0/19 table 41
ip rule add from 8.140.160.0/19 table 42
ip rule add from 8.140.192.0/19 table 41
ip rule add from 8.140.224.0/19 table 42


ip rule add from 8.144.0.0/19 table 41
ip rule add from 8.144.32.0/19 table 42
ip rule add from 8.144.64.0/19 table 41
ip rule add from 8.144.96.0/19 table 42
ip rule add from 8.144.128.0/19 table 41
ip rule add from 8.144.160.0/19 table 42
ip rule add from 8.144.192.0/19 table 41
ip rule add from 8.144.224.0/19 table 42

ip rule add from 8.148.0.0/19 table 41
ip rule add from 8.148.32.0/19 table 42
ip rule add from 8.148.64.0/19 table 41
ip rule add from 8.148.96.0/19 table 42
ip rule add from 8.148.128.0/19 table 41
ip rule add from 8.148.160.0/19 table 42
ip rule add from 8.148.192.0/19 table 41
ip rule add from 8.148.224.0/19 table 42

ip rule add from 8.152.0.0/19 table 41
ip rule add from 8.152.32.0/19 table 42
ip rule add from 8.152.64.0/19 table 41
ip rule add from 8.152.96.0/19 table 42
ip rule add from 8.152.128.0/19 table 41
ip rule add from 8.152.160.0/19 table 42
ip rule add from 8.152.192.0/19 table 41
ip rule add from 8.152.224.0/19 table 42

ip rule add from 8.156.0.0/20 table 21
ip rule add from 8.156.16.0/20 table 22
ip rule add from 8.158.0.0/20 table 41
ip rule add from 8.158.16.0/20 table 42

ip rule add from 8.160.0.0/20 table 51
ip rule add from 8.160.16.0/20 table 52
ip rule add from 8.162.0.0/20 table 11
ip rule add from 8.162.16.0/20 table 12
ip rule add from 8.164.0.0/20 table 11
ip rule add from 8.164.16.0/20 table 12

ip -6 rule add from 2a00:8::/52 table 21
ip -6 rule add from 2a00:8:0:1000::/52 table 22
ip -6 rule add from 2a00:8:2::/52 table 21
ip -6 rule add from 2a00:8:2:1000::/52 table 22
ip -6 rule add from 2a00:8:4::/52 table 21
ip -6 rule add from 2a00:8:4:1000::/52 table 22
ip -6 rule add from 2a00:8:6::/52 table 21
ip -6 rule add from 2a00:8:6:1000::/52 table 22
ip -6 rule add from 2a00:8:8::/52 table 21
ip -6 rule add from 2a00:8:8:1000::/52 table 22

ip -6 rule add from 2a00:8:10::/52 table 21
ip -6 rule add from 2a00:8:10:1000::/52 table 22
ip -6 rule add from 2a00:8:12::/52 table 21
ip -6 rule add from 2a00:8:12:1000::/52 table 22
ip -6 rule add from 2a00:8:14::/52 table 21
ip -6 rule add from 2a00:8:14:1000::/52 table 22
ip -6 rule add from 2a00:8:16::/52 table 21
ip -6 rule add from 2a00:8:16:1000::/52 table 22
ip -6 rule add from 2a00:8:18::/52 table 21
ip -6 rule add from 2a00:8:18:1000::/52 table 22

ip -6 rule add from 2a00:8:20::/52 table 21
ip -6 rule add from 2a00:8:20:1000::/52 table 22
ip -6 rule add from 2a00:8:22::/52 table 21
ip -6 rule add from 2a00:8:22:1000::/52 table 22
ip -6 rule add from 2a00:8:24::/52 table 21
ip -6 rule add from 2a00:8:24:1000::/52 table 22
ip -6 rule add from 2a00:8:26::/52 table 21
ip -6 rule add from 2a00:8:26:1000::/52 table 22
ip -6 rule add from 2a00:8:28::/52 table 21
ip -6 rule add from 2a00:8:28:1000::/52 table 22

ip -6 rule add from 2a00:8:30::/52 table 21
ip -6 rule add from 2a00:8:30:1000::/52 table 22
ip -6 rule add from 2a00:8:32::/52 table 21
ip -6 rule add from 2a00:8:32:1000::/52 table 22
ip -6 rule add from 2a00:8:34::/52 table 21
ip -6 rule add from 2a00:8:34:1000::/52 table 22
ip -6 rule add from 2a00:8:36::/52 table 21
ip -6 rule add from 2a00:8:36:1000::/52 table 22
ip -6 rule add from 2a00:8:38::/52 table 21
ip -6 rule add from 2a00:8:38:1000::/52 table 22

ip -6 rule add from 2a00:8:40::/52 table 21
ip -6 rule add from 2a00:8:40:1000::/52 table 22
ip -6 rule add from 2a00:8:42::/52 table 21
ip -6 rule add from 2a00:8:42:1000::/52 table 22
ip -6 rule add from 2a00:8:44::/52 table 21
ip -6 rule add from 2a00:8:44:1000::/52 table 22
ip -6 rule add from 2a00:8:46::/52 table 21
ip -6 rule add from 2a00:8:46:1000::/52 table 22
ip -6 rule add from 2a00:8:46:2000::/52 table 21
ip -6 rule add from 2a00:8:46:3000::/52 table 22
ip -6 rule add from 2a00:8:46:4000::/52 table 21
ip -6 rule add from 2a00:8:46:5000::/52 table 22
ip -6 rule add from 2a00:8:46:6000::/52 table 21
ip -6 rule add from 2a00:8:46:7000::/52 table 22
ip -6 rule add from 2a00:8:48::/52 table 21
ip -6 rule add from 2a00:8:48:1000::/52 table 22
ip -6 rule add from 2a00:8:48:2000::/52 table 21
ip -6 rule add from 2a00:8:48:3000::/52 table 22
ip -6 rule add from 2a00:8:48:4000::/52 table 21
ip -6 rule add from 2a00:8:48:5000::/52 table 22
ip -6 rule add from 2a00:8:48:6000::/52 table 21
ip -6 rule add from 2a00:8:48:7000::/52 table 22


ip -6 rule add from 2a00:8:50::/52 table 21
ip -6 rule add from 2a00:8:50:1000::/52 table 22
ip -6 rule add from 2a00:8:52::/52 table 21
ip -6 rule add from 2a00:8:52:1000::/52 table 22
ip -6 rule add from 2a00:8:54::/52 table 21
ip -6 rule add from 2a00:8:54:1000::/52 table 22
ip -6 rule add from 2a00:8:56::/52 table 21
ip -6 rule add from 2a00:8:56:1000::/52 table 22
ip -6 rule add from 2a00:8:58::/52 table 21
ip -6 rule add from 2a00:8:58:1000::/52 table 22

ip -6 rule add from 2a00:8:60::/52 table 21
ip -6 rule add from 2a00:8:60:1000::/52 table 22
ip -6 rule add from 2a00:8:62::/52 table 21
ip -6 rule add from 2a00:8:62:1000::/52 table 22
ip -6 rule add from 2a00:8:64::/52 table 21
ip -6 rule add from 2a00:8:64:1000::/52 table 22
ip -6 rule add from 2a00:8:66::/52 table 21
ip -6 rule add from 2a00:8:66:1000::/52 table 22
ip -6 rule add from 2a00:8:68::/52 table 21
ip -6 rule add from 2a00:8:68:1000::/52 table 22

ip -6 rule add from 2a00:8:70::/52 table 21
ip -6 rule add from 2a00:8:70:1000::/52 table 22
ip -6 rule add from 2a00:8:72::/52 table 21
ip -6 rule add from 2a00:8:72:1000::/52 table 22
ip -6 rule add from 2a00:8:74::/52 table 21
ip -6 rule add from 2a00:8:74:1000::/52 table 22
ip -6 rule add from 2a00:8:76::/52 table 11
ip -6 rule add from 2a00:8:76:1000::/52 table 12
ip -6 rule add from 2a00:8:78::/52 table 21
ip -6 rule add from 2a00:8:78:1000::/52 table 22

ip -6 rule add from 2a00:8:80::/52 table 11
ip -6 rule add from 2a00:8:80:1000::/52 table 12
ip -6 rule add from 2a00:8:82::/52 table 21
ip -6 rule add from 2a00:8:82:1000::/52 table 22
ip -6 rule add from 2a00:8:84::/52 table 21
ip -6 rule add from 2a00:8:84:1000::/52 table 22
ip -6 rule add from 2a00:8:86::/52 table 11
ip -6 rule add from 2a00:8:86:1000::/52 table 12
ip -6 rule add from 2a00:8:88::/52 table 11
ip -6 rule add from 2a00:8:88:1000::/52 table 12

ip -6 rule add from 2a00:8:90::/52 table 11
ip -6 rule add from 2a00:8:90:1000::/52 table 12
ip -6 rule add from 2a00:8:92::/52 table 11
ip -6 rule add from 2a00:8:92:1000::/52 table 12
ip -6 rule add from 2a00:8:94::/52 table 11
ip -6 rule add from 2a00:8:94:1000::/52 table 12
ip -6 rule add from 2a00:8:96::/52 table 11
ip -6 rule add from 2a00:8:96:1000::/52 table 12
ip -6 rule add from 2a00:8:98::/52 table 11
ip -6 rule add from 2a00:8:98:1000::/52 table 12

ip -6 rule add from 2a00:8:100::/52 table 11
ip -6 rule add from 2a00:8:100:1000::/52 table 12
ip -6 rule add from 2a00:8:102::/52 table 11
ip -6 rule add from 2a00:8:102:1000::/52 table 12
ip -6 rule add from 2a00:8:104::/52 table 41
ip -6 rule add from 2a00:8:104:1000::/52 table 42
ip -6 rule add from 2a00:8:106::/52 table 11
ip -6 rule add from 2a00:8:106:1000::/52 table 12
ip -6 rule add from 2a00:8:108::/52 table 11
ip -6 rule add from 2a00:8:108:1000::/52 table 12
ip -6 rule add from 2a00:8:108:2000::/52 table 11
ip -6 rule add from 2a00:8:108:3000::/52 table 12
ip -6 rule add from 2a00:8:108:4000::/52 table 11
ip -6 rule add from 2a00:8:108:5000::/52 table 12
ip -6 rule add from 2a00:8:108:6000::/52 table 11
ip -6 rule add from 2a00:8:108:7000::/52 table 12

ip -6 rule add from 2a00:8:110::/52 table 11
ip -6 rule add from 2a00:8:110:1000::/52 table 12
ip -6 rule add from 2a00:8:112::/52 table 11
ip -6 rule add from 2a00:8:112:1000::/52 table 12
ip -6 rule add from 2a00:8:114::/52 table 11
ip -6 rule add from 2a00:8:114:1000::/52 table 12
ip -6 rule add from 2a00:8:116::/52 table 11
ip -6 rule add from 2a00:8:116:1000::/52 table 12
ip -6 rule add from 2a00:8:118::/52 table 11
ip -6 rule add from 2a00:8:118:1000::/52 table 12

ip -6 rule add from 2a00:8:120::/52 table 11
ip -6 rule add from 2a00:8:120:1000::/52 table 12
ip -6 rule add from 2a00:8:122::/52 table 11
ip -6 rule add from 2a00:8:122:1000::/52 table 12
ip -6 rule add from 2a00:8:124::/52 table 31
ip -6 rule add from 2a00:8:124:1000::/52 table 32
ip -6 rule add from 2a00:8:126::/52 table 31
ip -6 rule add from 2a00:8:126:1000::/52 table 32
ip -6 rule add from 2a00:8:128::/52 table 31
ip -6 rule add from 2a00:8:128:1000::/52 table 32

ip -6 rule add from 2a00:8:130::/52 table 41
ip -6 rule add from 2a00:8:130:1000::/52 table 42
ip -6 rule add from 2a00:8:132::/52 table 41
ip -6 rule add from 2a00:8:132:1000::/52 table 42
ip -6 rule add from 2a00:8:134::/52 table 41
ip -6 rule add from 2a00:8:134:1000::/52 table 42
ip -6 rule add from 2a00:8:136::/52 table 41
ip -6 rule add from 2a00:8:136:1000::/52 table 42
ip -6 rule add from 2a00:8:138::/52 table 41
ip -6 rule add from 2a00:8:138:1000::/52 table 42

ip -6 rule add from 2a00:8:140::/52 table 41
ip -6 rule add from 2a00:8:140:1000::/52 table 42
ip -6 rule add from 2a00:8:140:4000::/52 table 41
ip -6 rule add from 2a00:8:140:5000::/52 table 42
ip -6 rule add from 2a00:8:140:8000::/52 table 41
ip -6 rule add from 2a00:8:140:9000::/52 table 42
ip -6 rule add from 2a00:8:140:c000::/52 table 41
ip -6 rule add from 2a00:8:140:d000::/52 table 42

ip -6 rule add from 2a00:8:144::/52 table 41
ip -6 rule add from 2a00:8:144:1000::/52 table 42
ip -6 rule add from 2a00:8:144:4000::/52 table 41
ip -6 rule add from 2a00:8:144:5000::/52 table 42
ip -6 rule add from 2a00:8:144:8000::/52 table 41
ip -6 rule add from 2a00:8:144:9000::/52 table 42
ip -6 rule add from 2a00:8:144:c000::/52 table 41
ip -6 rule add from 2a00:8:144:d000::/52 table 42

ip -6 rule add from 2a00:8:148::/52 table 41
ip -6 rule add from 2a00:8:148:1000::/52 table 42
ip -6 rule add from 2a00:8:148:4000::/52 table 41
ip -6 rule add from 2a00:8:148:5000::/52 table 42
ip -6 rule add from 2a00:8:148:8000::/52 table 41
ip -6 rule add from 2a00:8:148:9000::/52 table 42
ip -6 rule add from 2a00:8:148:c000::/52 table 41
ip -6 rule add from 2a00:8:148:d000::/52 table 42

ip -6 rule add from 2a00:8:152::/52 table 41
ip -6 rule add from 2a00:8:152:1000::/52 table 42
ip -6 rule add from 2a00:8:152:4000::/52 table 41
ip -6 rule add from 2a00:8:152:5000::/52 table 42
ip -6 rule add from 2a00:8:152:8000::/52 table 41
ip -6 rule add from 2a00:8:152:9000::/52 table 42
ip -6 rule add from 2a00:8:152:c000::/52 table 41
ip -6 rule add from 2a00:8:152:d000::/52 table 42

ip -6 rule add from 2a00:8:156::/52 table 21
ip -6 rule add from 2a00:8:156:1000::/52 table 22
ip -6 rule add from 2a00:8:158::/52 table 41
ip -6 rule add from 2a00:8:158:1000::/52 table 42

ip -6 rule add from 2a00:8:160::/52 table 51
ip -6 rule add from 2a00:8:160:1000::/52 table 52
ip -6 rule add from 2a00:8:162::/52 table 11
ip -6 rule add from 2a00:8:162:1000::/52 table 12
ip -6 rule add from 2a00:8:164::/52 table 11
ip -6 rule add from 2a00:8:164:1000::/52 table 12


if [ $RUN_OUTLINE == 1 ]
then
    ################################
    ### Creating outline address ###
    ################################
    ### MEDIA
    ip addr add 11.100.1.51/24 dev vlan${INDEX_CHANNEL}40
    ip -6 addr add 2a11:100:1::51/64 dev vlan${INDEX_CHANNEL}40
    ip addr add 11.100.26.51/24 dev vlan${INDEX_CHANNEL}50
    ip -6 addr add 2a11:100:26::51/64 dev vlan${INDEX_CHANNEL}50


    ### SIGNALING
    ip addr add 11.100.2.51/24 dev vlan${INDEX_CHANNEL}41
    ip -6 addr add 2a11:100:2::51/64 dev vlan${INDEX_CHANNEL}41
    ip addr add 11.100.27.51/24 dev vlan${INDEX_CHANNEL}51
    ip -6 addr add 2a11:100:27::51/64 dev vlan${INDEX_CHANNEL}51

    ip addr add 100.2.0.33 dev vlan${INDEX_CHANNEL}41 ###  chf_offline_1
    ip addr add 100.2.0.34 dev vlan${INDEX_CHANNEL}41 ###  chf_offline_2
    ip addr add 100.2.1.161 dev vlan${INDEX_CHANNEL}41 ###  chf_online_1
    ip addr add 100.2.1.162 dev vlan${INDEX_CHANNEL}41 ###  chf_online_2
    ip addr add 100.2.0.65 dev vlan${INDEX_CHANNEL}41 ###  pcf-1

    ip addr add 100.2.0.97 dev vlan${INDEX_CHANNEL}41 ###  pcrf
    ip addr add 100.2.0.98 dev vlan${INDEX_CHANNEL}41 ###  pcrf
    ip addr add 100.2.0.99 dev vlan${INDEX_CHANNEL}41 ###  pcrf
    ip addr add 100.2.0.100 dev vlan${INDEX_CHANNEL}41 ###  pcrf
    ip addr add 100.2.0.101 dev vlan${INDEX_CHANNEL}41 ###  pcrf

    ip addr add 100.2.0.129 dev vlan${INDEX_CHANNEL}41 ### redirect-pcrf-1
    ip addr add 100.2.0.130 dev vlan${INDEX_CHANNEL}41 ### redirect-pcrf-2
    ip addr add 100.2.0.121/24 dev vlan${INDEX_CHANNEL}41 ###  scp-1-ip-1
    ip addr add 100.2.0.122/24 dev vlan${INDEX_CHANNEL}41 ###  scp-1-ip-2
    ip addr add 100.2.0.123/24 dev vlan${INDEX_CHANNEL}41 ###  scp-2-ip-1
    ip addr add 100.2.0.124/24 dev vlan${INDEX_CHANNEL}41 ###  scp-2-ip-2


    ip addr add 100.2.0.161 dev vlan${INDEX_CHANNEL}41 ### ocs-1
    ip addr add 100.2.0.162 dev vlan${INDEX_CHANNEL}41 ### ocs-2-1
    ip addr add 100.2.0.163 dev vlan${INDEX_CHANNEL}41 ### ocs-2-2

    ip addr add 100.2.0.193 dev vlan${INDEX_CHANNEL}41 ### redirect-ocs-1
    ip addr add 100.2.0.194 dev vlan${INDEX_CHANNEL}41 ### redirect-ocs-2
    ip addr add 100.2.0.195 dev vlan${INDEX_CHANNEL}41 ### redirect-ocs-3

    ip addr add 100.2.0.133/24 dev vlan${INDEX_CHANNEL}41 ###  aaa-auth-1
    ip addr add 100.2.0.134/24 dev vlan${INDEX_CHANNEL}41 ###  aaa-auth-2


    ip addr add 100.2.1.1 dev vlan${INDEX_CHANNEL}41 ### pgw-rf-1
    ip addr add 100.2.1.2 dev vlan${INDEX_CHANNEL}41 ### pgw-rf-2

    ip addr add 100.2.1.97 dev vlan${INDEX_CHANNEL}41 ### dns

    ip addr add 100.2.1.129 dev vlan${INDEX_CHANNEL}41 ### ebm ecfe

    ip addr add 100.2.1.193 dev vlan${INDEX_CHANNEL}41 ###upf-1

    ip addr add 100.7.2.1 dev vlan${INDEX_CHANNEL}41 ###upf-forwarding radius
    ip addr add 100.7.2.2 dev vlan${INDEX_CHANNEL}41 ###upf-forwarding radius

    ip -6 addr add 2a00:100:2:1::1 dev vlan${INDEX_CHANNEL}41 ###  chf-1
    ip -6 addr add 2a00:100:2:2::1 dev vlan${INDEX_CHANNEL}41 ###  pcf-1

    ip -6 addr add 2a00:100:2:3::1 dev vlan${INDEX_CHANNEL}41 ###  pcrf
    ip -6 addr add 2a00:100:2:3::2 dev vlan${INDEX_CHANNEL}41 ###  pcrf
    ip -6 addr add 2a00:100:2:3::3 dev vlan${INDEX_CHANNEL}41 ###  pcrf
    ip -6 addr add 2a00:100:2:3::4 dev vlan${INDEX_CHANNEL}41 ###  pcrf
    ip -6 addr add 2a00:100:2:3::5 dev vlan${INDEX_CHANNEL}41 ###  pcrf

    ip -6 addr add 2a00:100:2:4::1 dev vlan${INDEX_CHANNEL}41 ### redirect-pcrf-1
    ip -6 addr add 2a00:100:2:4::2 dev vlan${INDEX_CHANNEL}41 ### redirect-pcrf-2

    ip -6 addr add 2a00:100:2:5::1 dev vlan${INDEX_CHANNEL}41 ### ocs-1
    ip -6 addr add 2a00:100:2:5::2 dev vlan${INDEX_CHANNEL}41 ### ocs-2-1
    ip -6 addr add 2a00:100:2:5::3 dev vlan${INDEX_CHANNEL}41 ### ocs-2-2

    ip -6 addr add 2a00:100:2:6::1 dev vlan${INDEX_CHANNEL}41 ### redirect-ocs-1
    ip -6 addr add 2a00:100:2:6::2 dev vlan${INDEX_CHANNEL}41 ### redirect-ocs-2
    ip -6 addr add 2a00:100:2:6::3 dev vlan${INDEX_CHANNEL}41 ### redirect-ocs-3

    ip -6 addr add 2a00:100:2:8::1 dev vlan${INDEX_CHANNEL}41 ### pgw-rf-1
    ip -6 addr add 2a00:100:2:8::2 dev vlan${INDEX_CHANNEL}41 ### pgw-rf-2



    ### OMCN
    ip addr add 100.3.0.97 dev vlan${INDEX_CHANNEL}42 ### shared_radius
    ip addr add 11.100.3.51/24 dev vlan${INDEX_CHANNEL}42
    ip -6 addr add 2a11:100:3::51/64 dev vlan${INDEX_CHANNEL}42

    ip addr add 11.100.28.51/24 dev vlan${INDEX_CHANNEL}52
    ip -6 addr add 2a11:100:28::51/64 dev vlan${INDEX_CHANNEL}52

    ip addr add 100.3.0.65 dev vlan${INDEX_CHANNEL}42 ### ebm

fi

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
