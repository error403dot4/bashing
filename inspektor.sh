#!/bin/bash
#0 9 15 * * ~/inspector.sh

#:	Name: inspector.sh
#:	Description: Run AWS inspector and send mail
#:	Dependencies: aws-cli, mailx
#:	Date: Jun 26, 2017
#:	Version: v1
#:	Author: Partybreaker <zurkoprekidac@gmail.com>

RECIPIENTS="x@mail.com"
logdate=$(date +"%d%m%Y")
templatearn="arn:aws:inspector:***"
sleeptime=1000

aws inspector start-assessment-run --assessment-template-arn $templatearn > ~/tmp.log
runarn=$(grep -F 1 tmp.log | awk '{ print $2 }' | cut -d'"' -f2)
rm -f ~/tmp.log
sleep $sleeptime

#chech inspector run status
runstatus=$(aws inspector describe-assessment-runs --assessment-run-arns $runarn --output text | tail -n 1 | awk '{print $2;}')
case $runstatus in
        COMPLETED)
        ;;
        COLLECTING_DATA | EVALUATING_RULES) sleep 300
        ;;
        COMPLETED_WITH_ERRORS | STOP_DATA_COLLECTION_PENDING | CANCELED)
        printf "Inspector $runstatus" | /bin/mail -s "inspector report" $RECIPIENTS
        exit
        ;;
        *) printf "Inspector assesment run status - $runstatus" | /bin/mail -s "inspector report" $RECIPIENTS
        exit
        ;;
esac
#get list of findings
aws inspector list-findings --assessment-run-arns $runarn > ~/FINDINGARNS.tmp
sed -n '/arn:aws:inspector:***/p' ~/FINDINGARNS.tmp | cut -d '"' -f2 > ~/FINDINGARNS.txt
rm -f ~/FINDINGARNS.tmp

#create report
while read i; do
        aws inspector describe-findings --finding-arns $i --output text >> ~/describe-findings.log
        printf "\n----------------------------------------------------------------------\n" >> ~/describe-findings.log
done < ~/FINDINGARNS.txt
rm -f ~/FINDINGARNS.txt

#check if report is empty and sedn email
if [ ! -s describe-findings.log ]
then
        printf "Inspector mounthly run should be done, but log is empty. Check AWS console report: https://console.aws.amazon.com/inspector/ \nRules packages: Common Vulnerabilities and Exposures-1.1\nDuration: 1 Hour\nTags: Inspector:true" | /bin/mail -s "inspector report $HOSTNAME" $RECIPIENTS
else
        printf "Inspector mounthly run should be done. Check AWS console report: https://console.aws.amazon.com/inspector/ \nRules packages: Common Vulnerabilities and Exposures-1.1\nDuration: 1 Hour\nTags: Inspector:true" | /bin/mail -s "inspector report $HOSTNAME" -a ~/describe-findings.log $RECIPIENTS
fi
mv ~/describe-findings.log ~/describe-findings_$logdate.log
