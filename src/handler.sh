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

    CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"
    # TODO: this
    IFS= read -d '@' -rn "$CONTENT_LENGTH" body
    body=${body%%$'\r'}
    log "BODY: $body"

    # TODO: function to parse object arrays
    while read -r entry; do
        [[ -z $entry ]] && continue
        IFS=$'\n' read -rd '' endpoint file <<< "$(split_object "$entry")"

        regex="^${endpoint}$"
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            handle_static_file "$file"
        fi
    done <<< "$(split_array "$SHIBA_STATIC_FILES")"

    while read -r entry; do
        [[ -z $entry ]] && continue
        IFS=$'\n' read -rd '' endpoint directory <<< "$(split_object "$entry")"

        regex="^${endpoint}(.*)$"
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            resource="${BASH_REMATCH[1]}"
            handle_static_file "$directory$resource"
        fi
    done <<< "$(split_array "$SHIBA_STATIC_DIRECTORIES")"

    while read -r entry; do
        [[ -z $entry ]] && continue
        IFS=$'\n' read -rd '' endpoint command <<< "$(split_object "$entry")"

        # TODO: match any request method and forward it to script
        # regex="^$(echo "$endpoint" | sed 's|<[^>]*>|([^/]+)|g')/?$"
        regex="^$(echo "$endpoint" | sed 's|<[^>]*>|([^/]+)|g')$"
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            handle_command "$command" "${BASH_REMATCH[@]:1}" <<< "$body"
        fi
    done <<< "$(split_array "$SHIBA_COMMANDS")"



    # for i in "${!resource_endpoints[@]}"; do
    #     endpoint="${resource_endpoints[i]}"
    #     resource_file="${resource_files[i]}"

    #     regex="^${endpoint}/?$"
    #     detail_regex="^${endpoint}/([^/]+)/?$"

    #     if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
    #         id="${BASH_REMATCH[1]}"
    #         handle_resource_retrieve "$resource_file" "$id"
    #     elif [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
    #         handle_resource_list "$resource_file"
    #     elif [[ $REQUEST_METHOD == "POST" ]] && [[ $REQUEST_URI =~ $regex ]]; then
    #         handle_resource_create "$resource_file"
    #     elif [[ $REQUEST_METHOD == "POST" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
    #         id="${BASH_REMATCH[1]}"
    #         handle_resource_update "$resource_file" "$id"
    #     elif [[ $REQUEST_METHOD == "DELETE" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
    #         id="${BASH_REMATCH[1]}"
    #         handle_resource_destroy "$resource_file" "$id"
    #     fi
    # done

    # # TODO: this block assumes endpoints have no trailing slashes
    # for i in "${!proxy_endpoints[@]}"; do
    #     endpoint="${proxy_endpoints[i]}"
    #     target="${proxy_targets[i]}"

    #     # TODO: something about the trailing slashes
    #     regex="^${endpoint}/(.*)$"

    #     log "RX $regex"
    #     # TODO: handle other methods
    #     if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
    #         path="${BASH_REMATCH[1]}"
    #         handle_proxy "$REQUEST_METHOD" "$target/$path"
    #     fi
    # done
}
export -f handle_client
