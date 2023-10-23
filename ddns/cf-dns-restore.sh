#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
# API key, see https://www.cloudflare.com/a/account/my-account,
# incorrect api-key results in E_UNAUTH error
CFKEY="global_key" #这是你的global key，
# Username, eg: user@example.com
CFUSER="mail@mail.com" #你在cloudflare的账号
# Zone name, eg: example.com
CFZONE_NAME="example.com"  #你要更新的域名的主域名，根域名，不带www
# Hostname to update, eg: homeserver.example.com
CFRECORD_NAME="app.exampleu.com" #这是你要更新的dns的域名
# Record type, A(IPv4)|AAAA(IPv6), default IPv4
CFRECORD_TYPE=A #ipv4是这个
# Cloudflare TTL for record, between 120 and 86400 seconds
CFTTL=1
#ip address
WAN_IP=1.2.3.4
# Ignore local file, update ip anyway
FORCE=false
WANIPSITE="http://ipv4.icanhazip.com"
HOME_PATH="/opt/ddns"
# Site to retrieve WAN ip, other examples are: bot.whatismyipaddress.com, https://api.ipify.org/ ...
if [ "$CFRECORD_TYPE" = "A" ]; then
  :
elif [ "$CFRECORD_TYPE" = "AAAA" ]; then
  WANIPSITE="http://ipv6.icanhazip.com"
else
  echo "$CFRECORD_TYPE specified is invalid, CFRECORD_TYPE can only be A(for IPv4)|AAAA(for IPv6)"
  exit 2
fi

# get parameter
while getopts k:u:h:z:t:f: opts; do
  case ${opts} in
    k) CFKEY=${OPTARG} ;;
    u) CFUSER=${OPTARG} ;;
    h) CFRECORD_NAME=${OPTARG} ;;
    z) CFZONE_NAME=${OPTARG} ;;
    t) CFRECORD_TYPE=${OPTARG} ;;
    f) FORCE=${OPTARG} ;;
  esac
done

# If required settings are missing just exit
if [ "$CFKEY" = "" ]; then
  echo "Missing api-key, get at: https://www.cloudflare.com/a/account/my-account"
  echo "and save in ${0} or using the -k flag"
  exit 2
fi
if [ "$CFUSER" = "" ]; then
  echo "Missing username, probably your email-address"
  echo "and save in ${0} or using the -u flag"
  exit 2
fi
if [ "$CFRECORD_NAME" = "" ]; then 
  echo "Missing hostname, what host do you want to update?"
  echo "save in ${0} or using the -h flag"
  exit 2
fi

# If the hostname is not a FQDN
if [ "$CFRECORD_NAME" != "$CFZONE_NAME" ] && ! [ -z "${CFRECORD_NAME##*$CFZONE_NAME}" ]; then
  CFRECORD_NAME="$CFRECORD_NAME.$CFZONE_NAME"
  echo " => Hostname is not a FQDN, assuming $CFRECORD_NAME"
fi



# Get zone_identifier & record_identifier
ID_FILE=$HOME_PATH/.cf-id_$CFRECORD_NAME.txt
if [ -f $ID_FILE ] && [ $(wc -l $ID_FILE | cut -d " " -f 1) == 4 ] \
  && [ "$(sed -n '3,1p' "$ID_FILE")" == "$CFZONE_NAME" ] \
  && [ "$(sed -n '4,1p' "$ID_FILE")" == "$CFRECORD_NAME" ]; then
    CFZONE_ID=$(sed -n '1,1p' "$ID_FILE")
    CFRECORD_ID=$(sed -n '2,1p' "$ID_FILE")
    echo "OLD id file is $CFZONE_ID $CFRECORD_ID ,path:$ID_FILE"
else
    echo "Updating zone_identifier & record_identifier"
    CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1 )
    echo "$CFZONE_ID" > $ID_FILE
    echo "$CFRECORD_ID" >> $ID_FILE
    echo "$CFZONE_NAME" >> $ID_FILE
    echo "$CFRECORD_NAME" >> $ID_FILE
    echo "NEW id file is $CFZONE_ID $CFRECORD_ID ,path:$ID_FILE"
fi
# If WAN is changed, update cloudflare
echo "Updating DNS to $WAN_IP"
echo "curl -s -X PUT https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID -H X-Auth-Email: $CFUSER -H X-Auth-Key: $CFKEY --data id:$CFZONE_ID,type:$CFRECORD_TYPE,name:$CFRECORD_NAME,content:$WAN_IP, ttl:$CFTTL, proxied:true"
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
  -H "X-Auth-Email: $CFUSER" \
  -H "X-Auth-Key: $CFKEY" \
  -H "Content-Type: application/json" \
  --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$WAN_IP\", \"ttl\":$CFTTL, \"proxied\":true}")

if [ "$RESPONSE" != "${RESPONSE%success*}" ] && [ "$(echo $RESPONSE | grep "\"success\":true")" != "" ]; then
  echo "Updated succesfuly!"
  exit
else
  echo 'Something went wrong :('
  echo "Response: $RESPONSE"
  exit 1
fi
