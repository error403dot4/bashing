#!/bin/bash

#:	Name: Host ping checker and reporter
#:	Description: Ping hosts, report if does not response
#:	Dependencies: mailx
#:	Date: 23 Oct 2017
#:	Version: v1
#:	Author: Partybreaker <zurkoprekidac@gmail.com>

ipAddress=192.168.2.

function logControl {
	if ! grep -q '64 bytes from' $ipAddress$i.log; then
		printf "No reply from $ipAddress$i\n" >> msg.txt
	fi

	if grep -q 'Destination Host Unreachable' $ipAddress$i.log; then
		printf "Destination Host Unreachable\n" >> msg.txt
	fi
}

for i in {3..6}
do
	ping -A -c 7 $ipAddress$i > $ipAddress$i.log
	logControl
done

if [ -e msg.txt ]
	then
		mail -s "ap offline" zurkoprekidac@gmail.com < msg.txt
fi

if [ -e msg.txt ]
	then
		rm msg.txt
fi

rm -rvf *.log
