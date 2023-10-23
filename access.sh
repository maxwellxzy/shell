#!/bin/bash
# This script use to check my proxy vps is working.
#SET THE ARGUMENT
my_proxy="http://127.0.0.1:1080"
ip_address="http://v4.ident.me"
access_address="https://xxx.com/test.txt"
error_log="error.log"
access_log="access.log"

##Set dir
SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR"

## Get The real ip
export all_proxy=""
get_realip=`curl -sL $ip_address`
echo -e "The real ip is $get_realip"

## Set proxy
export all_proxy=$my_proxy

## Get proxy ip
get_ip=`curl -sL $ip_address`
if [ -z $get_ip ]; then
        get_ip="CANNOT_GET_IP"
fi
echo -e "The proxy ip is $get_ip"

## Get access key words
get_pass=`curl -sL $access_address`
if [ -z $get_pass ]; then
        get_pass="BLOCKED_NETWORK"
        echo `date "+%Y-%m-%d %H:%M:%S"` $get_pass $get_ip $get_realip>> $error_log
        echo -e "Error! Can't Get the ACCESS keywords."
fi

echo `date "+%Y-%m-%d %H:%M:%S"` $get_pass $get_ip $get_realip>> $access_log
echo "Job Done! The keyword is $get_pass."
export all_proxy=""

# log file is bigger?
max_size=104857600
date1=$(date +"%Y%m%d")
if [ -f "$access_log" ]; then
        file_size=$(stat -c%s "$access_log")
        if [ $file_size -gt $max_size ]; then
                echo "The log file $access_log is $file_size, more than 1000M."
                echo "Compressing it..."
                tar czvf "$access_log"-"$date1".tar.gz $access_log
                echo "compression done."
                echo "Removing original log file..."
                rm "$access_log"
                echo "Removal done."
                echo "Touching a new file..."
                touch "$access_log"
                echo "Touch done."
        else
                echo "The log file $access_log is $file_size, less than 1000M.PASS."
        fi
else
        echo "The log file $access_log does not exist or is not a regular file."
fi

