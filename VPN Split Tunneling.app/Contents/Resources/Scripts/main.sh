#!/usr/bin/env bash

# sanity checks for argument 1/filepath
if [ -z "$1" ]; then
    echo "File not found"
    exit 2
fi


dnsServer=empty
interface=$(netstat -in | egrep '([0-9]{1,3}[\.]){3}[0-9]{1,3}' | awk '$1!~/^en0$/&&$3!~/^127/{print $1}')
excludeGateway=$(netstat -rnl -f inet | awk '$8~/'$interface'/{print $2}' | sort | uniq -c | awk '$1~/^1$/{print $2}')
listOfHosts=$(awk '$1~/[a-z]/{print}' $1)
addingNetworks () {
    for domainName in $listOfHosts
    do
        sudo sed -i '' '/'$domainName'/d' /etc/hosts
        ip=$(nslookup $domainName | awk '$1~/ddress:/&&$2!~/#/{print $2}')
        sudo route -n add $ip -interface $interface
        sudo tee -a /etc/hosts <<< "$ip $domainName"
    done
}
addingNetworks

removingNetAndIp () {
    for net in $(netstat -rnl -f inet | awk '$2!~/'$excludeGateway'/&&$2!~/'$interface'/&&$8~/'$interface'/&&$1~/\//{print $1}')
    do
        sudo route -n delete -net $net -interface $interface
    done

    for net in $(netstat -rnl -f inet | awk '$2!~/'$excludeGateway'/&&$2!~/'$interface'/&&$8~/'$interface'/&&$1~/192.168.0$/{print $1".0/24"}')
    do
        sudo route -n delete -net $net -interface $interface
    done

    for ip in $(netstat -rnl -f inet | awk '$2!~/'$excludeGateway'/&&$2!~/'$interface'/&&$8~/'$interface'/{print $1}')
    do
        sudo route -n delete $ip -interface $interface
    done

    for ip in $(netstat -rnl -f inet | awk '$2!~/'$excludeGateway'/&&$2!~/'$interface'/&&$8~/'$interface'/{print $1}' | awk 'BEGIN{FS="/"}{print $1}' | awk 'BEGIN{FS="."}{print NF,$0}' | sort | awk '{if ($1 == "1") print $2".0.0.0",$1,$2;if ($1 == "2") print $2".0.0",$1,$2;if ($1 == "3") print $2".0",$1,$2;if ($1 == "4") print $2,$1,$2}' | awk '{print $1}')
    do
        sudo route -n delete $ip -interface $interface
    done
}
removingNetAndIp
sudo networksetup -setdnsservers Wi-Fi $dnsServer
