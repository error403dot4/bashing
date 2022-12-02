#!/bin/bash

# Wordpress configuration checker
# Dependencies : curl, tor, jq, nmap
# Version 1.6.4 beta
# Usage: /bin/bash wordpress_check.sh protocol webiste report_preview(y/n)

#mozda neki live output?
#mozda neki banner?
#^^ovde dve stavke samo ako sakrijem curl output

if [ ! $1 ]; then
        read -p 'Enter website name (example: somewebsite.com): ' website
else
        website=$1
fi


if [ ! $2 ]; then
	if [ $(sudo nmap -sS -p 443 $website | grep 443 | cut -d " " -f 2) = "open" ]; then
		protocol=https
		printf "\n\nProtocol je $protocol\n\n"
	else
		protocol=http
		printf "HTTP Only\n" >> $rname
		printf "\n\nProtocol je $protocol\n\n"
	fi
else
        protocol=$2
fi

printf "\nChecking $website\n\n"

if [[ ! $(pidof tor) ]]; then
	sudo systemctl start tor.service
	printf "Starting TOR..."
	sleep 2
fi
sudo systemctl status tor.service

rlocation=reports
rname=report_$website-$(date +"%d-%m-%Y").txt

printf "time=$(date +"%H-%M-%S")\n" > $rname
printf "Findings::\n" >> $rname



printf "Passive version gathering\nWordPress version:\t" >> $rname
torify curl -s -X GET $website | grep http | grep -E '?ver=' | sed -E 's,href=|src=,THIIIIS,g' | awk -F "THIIIIS" '{print $2}' | cut -d "'" -f2
printf "\nPokusaj drugi:" >> $rname
torify curl -s -L $website | grep -i "content=\"wordpress" | cut -d "\"" -f 4 >> $rname
printf "\nPokusaj treci:" >> $rname
torify curl -s -L $website | grep -i "content=\"wordpress" >> $rname
printf "\n" >> $rname


pages=("wp-admin/upgrade.php"
	"wp-admin/install.php"
	"readme.html"
	"wp-config.php"
	"wp-admin/setup-config.php"
	"wp-config-sample.php"
	"wp-content/uploads/"
	"wp-content/themes/"
	"xmlrpc.php"
	"wp-cron.php"
	"wp-activate.php"
	"wp-login.php"
	"wp-admin"
	"wp-admin/admin-ajax.php"
	"admin"
	"license.txt"
	"robots.txt"
	"sitemap.xml"
	"wp-sitemap.xml"
	"info.php"
	"phpinfo.php"
	".htaccess"
	"phpmyadmin"
	"phpmyadmin.php"
	"adminer"
	"adminer.php"
	".git"
	".git/config"
	".git/logs/HEAD"
	".env"
	"_env"
	"api/.env"
	".environment"
	"README.md"
	"cgi-bin"
	"wp-content/uploads/data.txt"
	"test.php"
	)


for i in ${pages[@]}
do
	code=$(curl -I -s $protocol://$website/$i | grep HTTP | cut -d " " -f 2)
	ipaddr=$(torify curl -s -4 https://www.zx2c4.com/ip | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
	printf "\nPROVERA:\t $protocol://$website/$i\t$code\t$ipaddr\n"
	case $code in
		200)
			 printf "$protocol://$website/$i\n">>$rname
			 if [ $i == "wp-content/uploads/" ]; then
				 printf "\nUPLOADS 200\n"
				 printf "\nUPLOADS AVAILABE\n" >> testfile.txt
				 UPLOAD_ADDRESS=$protocol://$website/wp-content/uploads/
				 #nece to tako da radi
				 torify curl -s -F ‘data=testfile.txt’ $UPLOAD_ADDRESS
				 rm -f testfile.txt
				 unset UPLOAD_ADDRESS
				 if [ $(torify curl -s -I $protocol://$website/wp-content/uploads/testfile.txt | grep HTTP | cut -d " " -f 2) = 200 ]; then
					 printf "\nUPLOADS AVAILABE\n">>$rname
					 printf "\nUPLOADS AVAILABE\tUPLOADS AVAILABE\tUPLOADS AVAILABE\n"
				 fi
			 fi
			 ;;
		301)
			if [[ ! -z $(torify curl -s -I -L $protocol://$website/$i | grep HTTP | grep 200 | cut -d " " -f 2) ]]; then
				printf "$protocol://$website/$i\t$code\n">>$rname
			fi
			;;
		302)
			if [[ ! -z $(torify curl -s -I -L $protocol://$website/$i | grep HTTP | grep 200 | cut -d " " -f 2) ]]; then
				printf "$protocol://$website/$i\t$code\n">>$rname
			fi
			;;
		405)
			if [ $i = "xmlrpc.php" ]; then
				if [ $(torify curl -s -X POST -I $protocol://$website/$i| grep HTTP | cut -d " " -f 2) = 200 ]; then
					printf "$protocol://$website/$i\n">>$rname
				fi
			fi
			;;
		500)
			if [ $i = "wp-config-sample.php" ]; then
				printf "$protocol://$website/$i\n">>$rname
			fi
			;;
		*) 
			printf "\n"
			;;
	esac
	sudo systemctl reload tor.service

done

#user enumeration
printf "\nUser enumeration:\n">>$rname
torify curl -s -X GET  $protocol://$website/wp-json/wp/v2/users | jq '.[].slug' >> $rname
torify curl -s -I -X GET $protocol://$website/?author=1 >> $rname


if [[ ! -z $(torify curl -s -i $website | grep Server | cut -d " " -f 2) ]]; then printf "\n\nOther\nServer: $(curl -s -i $website | grep Server | cut -d " " -f 2)\n" >> $rname; fi

sudo systemctl stop tor.service

tm=$(grep time $rname | cut -d = -f 2)
printf "tm je \t $tm\n"
mv -v $rname $rlocation/report_$website-$(date +"%d-%m-%Y")__$tm.txt
printf "\n"
#error handling


if [ ! $3 ]; then
        read -p 'View report? y/n ' vrep
	if [ vrep==y  ]; then
		cat $rlocation/report_$website-$(date +"%d-%m-%Y")__$tm.txt
	fi
else
        vrep=$3
        if [ vrep==y  ]; then
                cat $rlocation/report_$website-$(date +"%d-%m-%Y")__$tm.txt
        fi 
fi

#https://book.hacktricks.xyz/pentesting/pentesting-web/wordpress
#https://datatracker.ietf.org/doc/html/rfc7231#section-6.5.3
#https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php
#https://twitter.com/Alra3ees/status/1400033361280778240
#https://twitter.com/0xJin/status/1399809593262358528
#https://smaranchand.com.np/2020/04/misconfigured-wordpress-takeover-to-remote-code-execution/
#https://ithemes.com/wordpress-wp-config-php-file-explained/
#https://secure.wphackedhelp.com/blog/hack-wordpress-website/#Reason_4_Incorrect_file_permissions
#https://wordpress.org/support/article/hardening-wordpress/
#https://wordpress.org/about/security/
#https://www.wpwhitesecurity.com/enumerate-wordpress-users-wpscan-security-scanner/
#https://lifeinhex.com/stealing-wordpress-credentials/
