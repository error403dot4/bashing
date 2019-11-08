#!/bin/bash

#:      Name: Internet connection speed checker
#:      Description: Checking Internet connection speed and reports if is too slow
#:      Dependencies: speedtest, grep, awk, sed, mailx
#:      Date: 08.02.2016.
#:      Version: v0.9
#:      Author: Partybreaker <zurkoprekidac@gmail.com>

#running speedtest and log into file for future processing
speedtest-cli >> speedtest.log
grep Download speedtest.log >> speedcheck.log
grep Upload speedtest.log >> speedcheck.log
rm -f speedtest.log

#removing all except value, it's only what we need for our puroposse
awk '{gsub(" Mbit/s", "");print}' speedcheck.log > litm01.log
awk '{gsub("Download: ", "");print}' litm01.log > litm02.log
awk '{gsub("Upload: ", "");print}' litm02.log > value.log
#now there is value.log with only two value, in first line is Downlaod speed in Mbit/s and second is Upload speed.
rm -f speedcheck.log litm01.log litm02.log

#add value to variables
valx=$(sed -n '1p' value.log)
valy=$(sed -n '2p' value.log)
#integer variables, because it's the only way to compare, and it's enough for speed checking
download=${valx%.*}
upload=${valy%.*}

#compare values
#set values as variables!!!
if [[ $download -lt 10 || $upload -lt 10 ]]
        then
                printf "Download speed: $valx Mb/s \nUpload speed: $valy Mb/s" > message.txt
                mail -s "Internet connection speed alert!" zurkoprekidac@gmail.com < message.txt
                rm -f message.txt
fi

rm value.log
