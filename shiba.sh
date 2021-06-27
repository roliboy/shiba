#!/usr/bin/env bash

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
    resource_file="$1"
    RESPONSE_HEADERS+=("Content-Length: $(stat --printf='%s' "$resource_file")")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    send "$(cat "$resource_file")"
}

handle_resource_retrieve() {
    resource_file="$1"
    resource_id="$2"

    data="$(cat "$resource_file")"
    element="$(jq -c ".[] | select(.id == $resource_id)" <<< "$data")"

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
    resource_file="$1"
 
    CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"

    read -rn "$CONTENT_LENGTH" body
    body=${body%%$'\r'}
    recv "BODY: $body"

    data="$(cat "$resource_file")"
    id="$(($(jq '.[-1].id' <<< "$data") + 1))"
    element="$(jq -c ". + {id: $id}" <<< "$body")"
    data="$(jq -c ". + [$element]" <<< "$data")"

    echo "$data" > "$resource_file"
    
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
    resource_file="$1"
    resource_id="$2"

    CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"

    read -rn "$CONTENT_LENGTH" body
    body=${body%%$'\r'}
    recv "BODY: $body"

    data="$(cat "$resource_file")"
    element="$(jq -c ". + {id: $resource_id}" <<< "$body")"
    data="$(jq -c "[ .[] | select(.id == $resource_id) = $element ]" <<< "$data")"

    echo "$data" > "$resource_file"

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
    resource_file="$1"
    resource_id="$2"

    data="$(cat "$resource_file")"
    element="$(jq -c ".[] | select(.id == $resource_id)" <<< "$data")"
    data="$(jq -c "map(select(.id != $resource_id))" <<< "$data")"

    echo "$data" > "$resource_file"

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



IFS='|'; endpoints=($SHIBA_RESOURCE_ENDPOINTS); unset IFS
IFS='|'; files=($SHIBA_RESOURCE_FILES); unset IFS


recv "ENDPOINTS: ${endpoints[*]}"
recv "FILES: ${files[*]}"

# TODO: something
if [[ $REQUEST_METHOD == "GET" ]]; then
    for i in "${!endpoints[@]}"; do 
        endpoint="${endpoints[i]}"
        resource_file="${files[i]}"

        regex="^${endpoint}/?$"
        detail_regex="^${endpoint}/([^/]+)/?$"

        if [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            handle_resource_retrieve "$resource_file" "$id"
        elif [[ $REQUEST_URI =~ $regex ]]; then
            handle_resource_list "$resource_file"
        fi
    done
elif [[ $REQUEST_METHOD == "POST" ]]; then
    for i in "${!endpoints[@]}"; do 
        endpoint="${endpoints[i]}"
        resource_file="${files[i]}"

        regex="^${endpoint}/?$"

        if [[ $REQUEST_URI =~ $regex ]]; then
            handle_resource_create "$resource_file"
        fi
    done
elif [[ $REQUEST_METHOD == "PUT" ]]; then
    for i in "${!endpoints[@]}"; do 
        endpoint="${endpoints[i]}"
        resource_file="${files[i]}"

        detail_regex="^${endpoint}/([^/]+)/?$"

        if [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            handle_resource_update "$resource_file" "$id"
        fi
    done
elif [[ $REQUEST_METHOD == "DELETE" ]]; then
    for i in "${!endpoints[@]}"; do 
        endpoint="${endpoints[i]}"
        resource_file="${files[i]}"

        detail_regex="^${endpoint}/([^/]+)/?$"

        if [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            handle_resource_destroy "$resource_file" "$id"
        fi
    done
fi
