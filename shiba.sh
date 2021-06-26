#!/usr/bin/env bash

warn() {
    echo "WARNING: $*" >>/tmp/log
}

recv() {
    echo "< $*" >>/tmp/log
}

send() {
    echo "> $*" >>/tmp/log
    printf '%s\r\n' "$*"
}



fail() {
   echo "$1"
   exit 1
}



read -r line || fail 400

line=${line%%$'\r'}
recv "$line"

read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION <<< "$line"

[ -n "$REQUEST_METHOD" ] || fail 400
[ -n "$REQUEST_URI" ] || fail 400
[ -n "$REQUEST_HTTP_VERSION" ] || fail 400

[ "$REQUEST_METHOD" = "GET" ] || fail 405

declare -a REQUEST_HEADERS

while read -r line; do
   line=${line%%$'\r'}
   recv "$line"
   [ -z "$line" ] && break
   REQUEST_HEADERS+=("$line")
done


DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
declare -a RESPONSE_HEADERS=(
   "Date: $DATE"
   "Expires: $DATE"
   "Server: shiba"
   "Content-Length: 8"
   "Content-Type: text/plain"
   "Access-Control-Allow-Origin: *"
   "Access-Control-Allow-Methods: OPTIONS, GET, POST, PUT, DELETE"
   "Access-Control-Allow-Headers: *"
   # "Access-Control-Allow-Credentials: true"
)

# 
# 
# 
# 

send "HTTP/1.0 200 OK"
for i in "${RESPONSE_HEADERS[@]}"; do
   send "$i"
done
send
# while read -r line; do
#    send "$line"
# done

send "AYY LMAO"