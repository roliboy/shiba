#!/usr/bin/env bash

startlog() {
    echo -n '' > /tmp/shibalog
}
export -f startlog

log() {
    echo "$*" >> /tmp/shibalog
}
export -f log

log_received_data() {
    log "RECEIVED $*"
}
export -f log_received_data

log_sent_data() {
    log "SENT $*"
}
export -f log_sent_data

log_request_method() {
    log "REQUEST_METHOD $*"
}
export -f log_request_method

log_request_uri() {
    log "REQUEST_URI $*"
}
export -f log_request_uri

log_request_header() {
    log "REQUEST_HEADER $*"
}
export -f log_request_header

log_response_header() {
    log "RESPONSE_HEADER $*"
}
export -f log_response_header

recv() {
    local data
    read -r data
    data=${data%%$'\r'}
    log_received_data "$data"
    echo -n "$data"
}
export -f recv

send() {
    log_sent_data "$*"
    echo -ne "$*\r\n"
}
export -f send

send_file() {
    log_sent_data "file $1"
    cat "$1"
}
export -f send_file

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}
export -f trim


fail() {
    echo "$1"
    exit 1
}
export -f fail

handle_static_file() {
    file="$1"
    RESPONSE_HEADERS+=("Content-Length: $(stat --printf='%s' "$file")")
    RESPONSE_HEADERS+=("Content-Type: application/png")
    
    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    send_file "$file"
}
export -f handle_static_file

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
export -f handle_resource_list

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
export -f handle_resource_retrieve

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
export -f handle_resource_create

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
export -f handle_resource_update


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
export -f handle_resource_destroy

handle_client() {
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

    IFS='|' read -ra resource_endpoints <<< "$SHIBA_RESOURCE_ENDPOINTS"
    IFS='|' read -ra resource_files <<< "$SHIBA_RESOURCE_FILES"
    IFS='|' read -ra static_endpoints <<< "$SHIBA_STATIC_ENDPOINTS"
    IFS='|' read -ra static_files <<< "$SHIBA_STATIC_FILES"

    DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
    declare -a RESPONSE_HEADERS=(
        "Date: $DATE"
        "Expires: $DATE"
        "Server: shiba"
        "Access-Control-Allow-Origin: *"
        "Access-Control-Allow-Methods: OPTIONS, GET, POST, PUT, DELETE"
        "Access-Control-Allow-Headers: *"
    )

    for i in "${!resource_endpoints[@]}"; do
        endpoint="${resource_endpoints[i]}"
        resource_file="${resource_files[i]}"

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

    for i in "${!static_endpoints[@]}"; do
        endpoint="${static_endpoints[i]}"
        static_file="${static_files[i]}"

        regex="^${endpoint}$"
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            handle_static_file "$static_file"
        fi
    done
}
export -f handle_client