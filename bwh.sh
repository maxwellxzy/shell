#!/bin/bash
# Get bandwaghon vps bandwidth usage
#SET THE ARGUMENT
VEID=123456
KEY="private_key_number"
url="https://api.64clouds.com/v1/getServiceInfo?veid=$VEID&api_key=$KEY"
error_log="bwh_error.log"
access_log="bwh_access.log"

##Set dir
SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR"
## Get access key words
pass=`curl -sL $url`
if [ ${#pass} -lt 100 ]; then
	pass1=`echo $pass|sed ":a;N;s/\n//g;ta"`
	echo -n $(date +"%D %T")" | ERROR:$pass1" >> $error_log
	echo -n $(date +"%D %T")" | ERROR:$pass1" >> $access_log
	exit 2
fi
counter=$(echo $pass | jq '.data_counter')
reset_day=$(echo $pass |jq '.data_next_reset')
reset_day2=$(date -d @$reset_day +"%Y-%m-%d")
counter2=$(echo "scale=2;($counter / 1024 / 1024 / 1024)"|bc -l)
echo $(date +"%D %T")" | USAGE:"$counter2"GB/500GB | RESETDAT:"$reset_day2 >> $access_log
exit 1
