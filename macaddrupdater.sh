#!/bin/bash

#:	Name: macaddressadd.sh
#:	Description: Engenius access point (openWRT) mac address whitelist updater
#:	Date: September 2019
#:	Version: v1
#:	Author: Partybreaker <zurkoprekidac@gmail>

dirname=$(date +"%Y-%m-%d")
declare -i i=0

#checking for files
if [ ! -ef "*.tar.gz" ]
then
	echo "ERR: Script must be placed along with Engenius configuration files!"
	exit 1
fi

#directory cheking and naming
if [ -e "../$dirname"  ]
then
	while [ -e "../$dirname"  ]; do
		i=$((i+1))
		unset dirname
		dirname=$(date +"%Y-%m-%d")_$i
	done
	echo "Directory name: $dirname"
	mkdir ../$dirname && cp -rv * ../$dirname && cd ../$dirname
else
	mkdir ../$dirname && cp -rv * ../$dirname && cd ../$dirname
fi

#mac address checker and editor
read -p "Enter MAC address: " macaddress

if [ $(echo "$macaddress" | grep -i "-") ]
then
        macaddress=$(sed 's/-/:/g' <<< $macaddress)
fi

if [[ $(awk -F":" '{print NF-1}' <<< "$macaddress") != 5 ]]
then
        echo "ERR: Incorrect MAC address format!"
        exit 1
elif ! [[ $macaddress =~ ^[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]$ ]]
then
        echo "ERR: Incorrect MAC address format!"
        exit 1
fi
macaddress="${macaddress^^}"

#add address
for i in {3..8}; do
	tar xzf etc_0$i.tar.gz
	rm -fv etc_0$i.tar.gz
	if  grep -i $macaddress etc/config/wireless
	then
		echo "ERR: Address already exist in configuration file etc_0$i.tar.gz"
		exit 1
	fi
	sed -i '/option allowmaclist/ s/.$/ '"${macaddress}"''"'"'/' etc/config/wireless
	tar czf etc_0$i.tar.gz etc
	rm -fr etc
	echo "Configuration file etc_0$i.tar.gz is ready"
done
