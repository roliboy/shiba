#!/usr/bin/env bash

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

# TODO: this
parse_endpoints() {
    local -n array="$1"
    data="$(cat)"
    log "DATA: $data"
    local IFS=$'\n'
    for entry in $(split_array "$data"); do
        [[ -z $entry ]] && continue
        array+=("$entry")
    done
}
export -f parse_endpoints


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

    # TODO: something with this
    DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
    declare -a RESPONSE_HEADERS=(
        "Date: $DATE"
        "Expires: $DATE"
        "Server: shiba"
        "Access-Control-Allow-Origin: *"
        "Access-Control-Allow-Methods: OPTIONS, GET, POST, PUT, DELETE"
        "Access-Control-Allow-Headers: *"
    )

    # # TODO: remove
    # # TODO: skip when no content-length header is present
    # CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"
    # # TODO: this
    # IFS= read -d '@' -rn "$CONTENT_LENGTH" body
    # body=${body%%$'\r'}
    # log "BODY: $body"


    parse_endpoints STATIC_FILES <<< "$SHIBA_STATIC_FILES"
    parse_endpoints STATIC_DIRECTORIES <<< "$SHIBA_STATIC_DIRECTORIES"
    parse_endpoints COMMANDS <<< "$SHIBA_COMMANDS"
    parse_endpoints PROXIES <<< "$SHIBA_PROXIES"
    parse_endpoints RESOURCES <<< "$SHIBA_RESOURCES"

    # TODO: merge these two (generalize regex)
    for entry in "${STATIC_FILES[@]}"; do
        IFS=$'\n' read -rd '' endpoint file <<< "$(split_object "$entry")"

        regex="^${endpoint}$"
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            handle_static_file "$file"
        fi
    done

    for entry in "${STATIC_DIRECTORIES[@]}"; do
        IFS=$'\n' read -rd '' endpoint directory <<< "$(split_object "$entry")"

        regex="^${endpoint}(.*)$"
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            resource="${BASH_REMATCH[1]}"
            handle_static_file "$directory$resource"
        fi
    done

    for entry in "${COMMANDS[@]}"; do
        [[ -z $entry ]] && continue
        IFS=$'\n' read -rd '' endpoint command <<< "$(split_object "$entry")"

        log "ENTRY $entry"
        log "ENDPOINT $endpoint"
        log "command $command"

        # TODO: match any request method and forward it to script
        # regex="^$(echo "$endpoint" | sed 's|<[^>]*>|([^/]+)|g')/?$"
        # regex="^$(echo "$endpoint" | sed 's|<[^>]*>|([^/]+)|g')$"
        regex="^$(echo "$endpoint" | sed 's|{[^}]*}|([^/]+)|g')$"
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            handle_command "$command" "${BASH_REMATCH[@]:1}"
        fi
    done

    for entry in "${PROXIES[@]}"; do
        [[ -z $entry ]] && continue
        IFS=$'\n' read -rd '' endpoint server <<< "$(split_object "$entry")"

        # TODO: something about the trailing slashes
        regex="^${endpoint}(/.*)?$"

        # TODO: handle other methods
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            path="${BASH_REMATCH[1]}"
            handle_proxy "$REQUEST_METHOD" "$server$path"
        fi
    done

    for entry in "${RESOURCES[@]}"; do
        IFS=$'\n' read -rd '' endpoint resource <<< "$(split_object "$entry")"

        regex="^${endpoint}/?$"
        detail_regex="^${endpoint}/([^/]+)/?$"

        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            log_regex_match "$detail_regex"
            log_endpoint_match "$endpoint"
            handle_resource_retrieve "$resource" "$id"
        elif [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            handle_resource_list "$resource"
        elif [[ $REQUEST_METHOD == "POST" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            handle_resource_create "$resource"
        elif [[ $REQUEST_METHOD == "PUT" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            log_regex_match "$detail_regex"
            log_endpoint_match "$endpoint"
            handle_resource_update "$resource" "$id"
        elif [[ $REQUEST_METHOD == "DELETE" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            log_regex_match "$detail_regex"
            log_endpoint_match "$endpoint"
            handle_resource_destroy "$resource" "$id"
        fi
    done
}
export -f handle_client
