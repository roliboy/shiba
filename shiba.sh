#!/usr/bin/env bash

startlog() {
    echo -n '' > /tmp/shibalog
}

log() {
    echo "$*" >> /tmp/shibalog
}

log_received_data() {
    log "RECEIVED $*"
}

log_sent_data() {
    log "SENT $*"
}

log_request_method() {
    log "REQUEST_METHOD $*"
}

log_request_uri() {
    log "REQUEST_URI $*"
}

log_request_header() {
    log "REQUEST_HEADER $*"
}

log_response_header() {
    log "RESPONSE_HEADER $*"
}

recv() {
    local data
    read -r data
    data=${data%%$'\r'}
    log_received_data "$data"
    echo -n "$data"
}

send() {
    log_sent_data "$*"
    echo -ne "$*\r\n"
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


startlog

read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION <<< "$(recv)"
[[ -n $REQUEST_METHOD ]] || fail 400
[[ -n $REQUEST_URI ]] || fail 400
[[ -n $REQUEST_HTTP_VERSION ]] || fail 400

log_request_method "$REQUEST_METHOD"
log_request_uri "$REQUEST_URI"

# TODO: name reference
declare -A REQUEST_HEADERS
while line="$(recv)"; do
    [ -z "$line" ] && break
    # TODO: method for parsing headers
    IFS=':' read -ra content <<< "$line"
    header="${content[0]}"
    value="$(trim "${content[1]}")"
    REQUEST_HEADERS[$header]="$value"
    log_request_header "${header} => $value"
done


IFS='|' read -ra endpoints <<< "$SHIBA_RESOURCE_ENDPOINTS"
IFS='|' read -ra files <<< "$SHIBA_RESOURCE_FILES"


for i in "${!endpoints[@]}"; do
    endpoint="${endpoints[i]}"
    resource_file="${files[i]}"

    regex="^${endpoint}/?$"
    detail_regex="^${endpoint}/([^/]+)/?$"

    if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
        id="${BASH_REMATCH[1]}"
        handle_resource_retrieve "$resource_file" "$id"
    elif [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
        handle_resource_list "$resource_file"
    elif [[ $REQUEST_METHOD == "POST" ]] && [[ $REQUEST_URI =~ $regex ]]; then
        handle_resource_create "$resource_file"
    elif [[ $REQUEST_METHOD == "POST" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
        id="${BASH_REMATCH[1]}"
        handle_resource_update "$resource_file" "$id"
    elif [[ $REQUEST_METHOD == "DELETE" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
        id="${BASH_REMATCH[1]}"
        handle_resource_destroy "$resource_file" "$id"
    fi
done
