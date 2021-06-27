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

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}


fail() {
   echo "$1"
   exit 1
}


DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
declare -a RESPONSE_HEADERS=(
   "Date: $DATE"
   "Expires: $DATE"
   "Server: shiba"
   "Access-Control-Allow-Origin: *"
   "Access-Control-Allow-Methods: OPTIONS, GET, POST, PUT, DELETE"
   "Access-Control-Allow-Headers: *"
)

handle_resource_list() {
   RESPONSE_HEADERS+=("Content-Length: $(($(stat --printf='%s' resource) + 0))")
   RESPONSE_HEADERS+=("Content-Type: application/json")
   
   send "HTTP/1.0 200 OK"
   for i in "${RESPONSE_HEADERS[@]}"; do
      send "$i"
   done
   send

   send "$(cat resource)"
}

handle_resource_retrieve() {
   regex="^/resource/([^/]*)/?$"

   if [[ $REQUEST_URI =~ $regex ]]; then
      recv "REGEX: ${BASH_REMATCH[*]}"
      id="${BASH_REMATCH[1]}"
   else
      exit 69
   fi

   data="$(cat resource)"
   element="$(jq -c ".[] | select(.id == $id)" <<< "$data")"

   RESPONSE_HEADERS+=("Content-Length: ${#element}")
   RESPONSE_HEADERS+=("Content-Type: application/json")
   
   send "HTTP/1.0 200 OK"
   for i in "${RESPONSE_HEADERS[@]}"; do
      send "$i"
   done
   send

   send "$element"
}

handle_resource_create() {
   CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"

   read -rn "$CONTENT_LENGTH" body
   body=${body%%$'\r'}
   recv "BODY: $body"

   data="$(cat resource)"
   id="$(($(jq '.[-1].id' <<< "$data") + 1))"
   element="$(jq -c ". + {id: $id}" <<< "$body")"
   data="$(jq -c ". + [$element]" <<< "$data")"

   echo "$data" > resource
   
   RESPONSE_HEADERS+=("Content-Length: ${#element}")
   RESPONSE_HEADERS+=("Content-Type: application/json")
   send "HTTP/1.0 201 CREATED"
   for i in "${RESPONSE_HEADERS[@]}"; do
      send "$i"
   done
   send

   send "$element"
}

handle_resource_update() {
   # path="/resource/<id>"
   regex="^/resource/([^/]*)/?$"

   if [[ $REQUEST_URI =~ $regex ]]; then
      recv "REGEX: ${BASH_REMATCH[*]}"
      id="${BASH_REMATCH[1]}"
   else
      exit 69
   fi

   CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"

   read -rn "$CONTENT_LENGTH" body
   body=${body%%$'\r'}
   recv "BODY: $body"

   data="$(cat resource)"
   element="$(jq -c ". + {id: $id}" <<< "$body")"
   data="$(jq -c "[ .[] | select(.id == $id) = $element ]" <<< "$data")"

   echo "$data" > resource

   RESPONSE_HEADERS+=("Content-Length: ${#element}")
   RESPONSE_HEADERS+=("Content-Type: application/json")
   
   send "HTTP/1.0 200 OK"
   for i in "${RESPONSE_HEADERS[@]}"; do
      send "$i"
   done
   send

   send "$element"
}


handle_resource_destroy() {
   regex="^/resource/([^/]*)/?$"

   if [[ $REQUEST_URI =~ $regex ]]; then
      recv "REGEX: ${BASH_REMATCH[*]}"
      id="${BASH_REMATCH[1]}"
   else
      exit 69
   fi

   data="$(cat resource)"
   element="$(jq -c ".[] | select(.id == $id)" <<< "$data")"
   data="$(jq -c "map(select(.id != $id))" <<< "$data")"

   echo "$data" > resource

   RESPONSE_HEADERS+=("Content-Length: ${#element}")
   RESPONSE_HEADERS+=("Content-Type: application/json")
   
   send "HTTP/1.0 200 OK"
   for i in "${RESPONSE_HEADERS[@]}"; do
      send "$i"
   done
   send

   send "$element"
}



read -r line || fail 400
line=${line%%$'\r'}
recv "$line"

read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION <<< "$line"
declare -A REQUEST_HEADERS
while read -r line; do
   line=${line%%$'\r'}
   recv "$line"
   [ -z "$line" ] && break
   IFS=':' read -ra content <<< "$line"
   header="${content[0]}"
   value="$(trim "${content[1]}")"
   REQUEST_HEADERS[$header]="$value"
done


for key in "${!REQUEST_HEADERS[@]}";
   do recv "HEADER $key => ${REQUEST_HEADERS[$key]}";
done


[ -n "$REQUEST_METHOD" ] || fail 400
[ -n "$REQUEST_URI" ] || fail 400
[ -n "$REQUEST_HTTP_VERSION" ] || fail 400



if [[ $REQUEST_METHOD == "GET" ]]; then
   handle_resource_retrieve
   # handle_resource_list
elif [[ $REQUEST_METHOD == "POST" ]]; then
   handle_resource_create
elif [[ $REQUEST_METHOD == "PUT" ]]; then
   handle_resource_update
elif [[ $REQUEST_METHOD == "DELETE" ]]; then
   handle_resource_destroy
fi
