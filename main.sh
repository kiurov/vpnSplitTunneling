#!/usr/bin/env bash

# dnsServer=8.8.8.8
dnsServer=empty
listOfHosts=$(gawk '$1~/[a-z]/{print}' $1)
# List of necessary domains


# VPN interface definition
interface=$(netstat -rnl -f inet | gawk '$2~/^10./&&$3~/10./{print $8}' | sort | uniq)
# netstat -in | egrep '([0-9]{1,3}[\.]){3}[0-9]{1,3}'


# Manual removing
# netstat -rnl -f inet | gawk '$1!~/^10./&&$3~/^10./&&$8~/'$interface'/{print $1}' | gawk '{if ($1~"/") print "sudo route -n delete -net "$1;else if ($1~"192.168.0$") print "sudo route -n delete -net "$1".0/24"; else print "sudo route -n delete "$1}' | sort

# Next step
# netstat -rnl -f inet | gawk '$1!~/^10./&&$3~/^10./&&$8~/'$interface'/{print $1}' | gawk 'BEGIN{FS="/"}{print $1}' | gawk 'BEGIN{FS="."}{print NF,$0}' | sort | gawk '{if ($1 == "1") print $2".0.0.0",$1,$2;if ($1 == "2") print $2".0.0",$1,$2;if ($1 == "3") print $2".0",$1,$2;if ($1 == "4") print $2,$1,$2}' | column -t | gawk '{print "sudo route -n delete "$1}'

 
sudo echo
echo "##################################################################################################################################################"
echo "Current configuration in /etc/hosts"
cat /etc/hosts
echo "##################################################################################################################################################"
echo
echo "##################################################################################################################################################"
echo "Removing networks and ip addresses from the routing table for the VPN interface $interface"
removingNetAndIp () {
    for net in $(netstat -rnl -f inet | gawk '$1!~/^10./&&$3~/^10./&&$8~/'$interface'/{print $1}' | gawk '{if ($1~"/") print $1}' | sort)
    do
        sudo route -n delete -net $net -interface $interface
    done

    for net in $(netstat -rnl -f inet | gawk '$1!~/^10./&&$3~/^10./&&$8~/'$interface'/{print $1}' | gawk '{if ($1~"192.168.0$") print $1".0/24"}' | sort)
    do
        sudo route -n delete -net $net -interface $interface
    done

    for ip in $(netstat -rnl -f inet | gawk '$1!~/^10./&&$3~/^10./&&$8~/'$interface'/{print $1}' | sort)
    do
        sudo route -n delete $ip -interface $interface
    done

    for ip in $(netstat -rnl -f inet | gawk '$1!~/^10./&&$3~/^10./&&$8~/'$interface'/{print $1}' | gawk 'BEGIN{FS="/"}{print $1}' | gawk 'BEGIN{FS="."}{print NF,$0}' | sort | gawk '{if ($1 == "1") print $2".0.0.0",$1,$2;if ($1 == "2") print $2".0.0",$1,$2;if ($1 == "3") print $2".0",$1,$2;if ($1 == "4") print $2,$1,$2}' | gawk '{print $1}')
    do
        sudo route -n delete $ip -interface $interface
    done
}
removingNetAndIp &> /dev/null
echo "Done"
echo "##################################################################################################################################################"



echo
echo "##################################################################################################################################################"
echo "Deletion old hosts from the file /etc/hosts, adding networks to the routing table for the VPN interface $interface, refreshing hosts in /etc/hosts"
# domainName=
addingNetworks () {
    for domainName in $listOfHosts
    do
        # sudo sed '/'$domainName'/d' /etc/hosts
        sudo sed -i '' '/'$domainName'/d' /etc/hosts
        ip=$(nslookup $domainName | gawk '$1~/ddress:/&&$2!~/#/{print $2}')
        # net=$(nslookup $domainName | gawk '$1~/ddress:/&&$2!~/#/{print $2}' | gawk 'BEGIN{FS=OFS="."}{print $1,$2,$3,"0"}')
        sudo route -n add $ip -interface $interface
        # sudo route -n add -net $net -interface $interface
        sudo tee -a /etc/hosts <<< "$ip $domainName"
        # echo "$ip\t$domainName" | sudo tee -a /etc/hosts
    done
}
addingNetworks &> /dev/null
# addingNetworks
echo "Done"
echo "##################################################################################################################################################"


echo
echo "##################################################################################################################################################"
echo "Removing the remaining networks and ip addresses from the routing table for the VPN interface $interface"
removingRemainingNetworksAndIpAddresses () {
    excludeGateway=$(netstat -rnl -f inet | gawk '$8~/'$interface'/{print $2}' | sort | uniq -c | gawk '$1~/^1$/{print $2}') ; echo $excludeGateway

    for net in $(netstat -rnl -f inet | gawk '$2!~/'$excludeGateway'/&&$2!~/'$interface'/&&$8~/'$interface'/{print $0}' | gawk '{if ($1~"/") print $1}' | sort)
    do
        sudo route -n delete -net $net -interface $interface
    done

    for ip in $(netstat -rnl -f inet | gawk '$2!~/'$excludeGateway'/&&$2!~/'$interface'/&&$8~/'$interface'/{print $1}' | sort)
    do
        sudo route -n delete $ip -interface $interface
    done

    for ip in $(netstat -rnl -f inet | gawk '$2!~/'$excludeGateway'/&&$2!~/'$interface'/&&$8~/'$interface'/{print $1}' | gawk 'BEGIN{FS="/"}{print $1}' | gawk 'BEGIN{FS="."}{print NF,$0}' | sort | gawk '{if ($1 == "1") print $2".0.0.0",$1,$2;if ($1 == "2") print $2".0.0",$1,$2;if ($1 == "3") print $2".0",$1,$2;if ($1 == "4") print $2,$1,$2}' | gawk '{print $1}')
    do
        sudo route -n delete $ip -interface $interface
    done
}
removingRemainingNetworksAndIpAddresses &> /dev/null
echo "Done"
echo "##################################################################################################################################################"



echo
echo "##################################################################################################################################################"
echo "Current DNS and VPN DNS servers"
# networksetup -listallnetworkservices
networksetup -getdnsservers Wi-Fi
echo
echo "Removing VPN DNS servers"
# networksetup -getdnsservers Wi-Fi | tr -s '\r\n' ' ' | gawk '{print}'
sudo networksetup -setdnsservers Wi-Fi $dnsServer
# sudo networksetup -setdnsservers Wi-Fi empty
# dnsServer=$(networksetup -getdnsservers Wi-Fi | tr -s '\r\n' ' ') | gawk '{print}' | gawk '{if ($1~"here") print "empty";else print}')
echo
echo "Current DNS and VPN DNS servers"
# networksetup -listallnetworkservices
networksetup -getdnsservers Wi-Fi
echo "Done"
echo "##################################################################################################################################################"




echo
echo "##################################################################################################################################################"
echo "Сurrent routing table for the VPN interface $interface"
netstat -ranl -f inet | gawk '$1~/estination/||$8~/'$interface'/{print}'
echo "##################################################################################################################################################"
echo
echo "##################################################################################################################################################"
echo "Updated configuration in /etc/hosts"
cat /etc/hosts
echo "##################################################################################################################################################"
echo

exit 0
