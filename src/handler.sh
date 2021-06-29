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

    IFS='|' read -ra resource_endpoints <<< "$SHIBA_RESOURCE_ENDPOINTS"
    IFS='|' read -ra resource_files <<< "$SHIBA_RESOURCE_FILES"
    IFS='|' read -ra static_endpoints <<< "$SHIBA_STATIC_ENDPOINTS"
    IFS='|' read -ra static_files <<< "$SHIBA_STATIC_FILES"
    IFS='|' read -ra static_directory_endpoints <<< "$SHIBA_STATIC_DIRECTORY_ENDPOINTS"
    IFS='|' read -ra static_directories <<< "$SHIBA_STATIC_DIRECTORIES"
    IFS='|' read -ra function_endpoints <<< "$SHIBA_FUNCTION_ENDPOINTS"
    IFS='|' read -ra function_targets <<< "$SHIBA_FUNCTION_TARGETS"
    IFS='|' read -ra proxy_endpoints <<< "$SHIBA_PROXY_ENDPOINTS"
    IFS='|' read -ra proxy_targets <<< "$SHIBA_PROXY_TARGETS"

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

    # TODO: this block assumes endpoints have no trailing slashes
    for i in "${!function_endpoints[@]}"; do
        endpoint="${function_endpoints[i]}"
        command="${function_targets[i]}"

        regex="^$(echo "$endpoint" | sed 's|<[^>]*>|([^/]+)|g')/?$"

        log "REGEX $regex"

        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            handle_command "$command" "${BASH_REMATCH[@]:1}"
        fi
        # if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
        #     resource="${BASH_REMATCH[1]}"
        #     handle_static_file "$directory/$resource"
        # fi
    done

    for i in "${!static_endpoints[@]}"; do
        endpoint="${static_endpoints[i]}"
        static_file="${static_files[i]}"

        regex="^${endpoint}$"
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            handle_static_file "$static_file"
        fi
    done

    # TODO: this block assumes endpoints have no trailing slashes
    for i in "${!static_directory_endpoints[@]}"; do
        endpoint="${static_directory_endpoints[i]}"
        directory="${static_directories[i]}"

        regex="^${endpoint}/(.*)$"
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            resource="${BASH_REMATCH[1]}"
            handle_static_file "$directory/$resource"
        fi
    done

    # TODO: this block assumes endpoints have no trailing slashes
    for i in "${!proxy_endpoints[@]}"; do
        endpoint="${proxy_endpoints[i]}"
        target="${proxy_targets[i]}"

        # TODO: something about the trailing slashes
        regex="^${endpoint}/(.*)$"

        log "RX $regex"
        # TODO: handle other methods
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            path="${BASH_REMATCH[1]}"
            handle_proxy "$REQUEST_METHOD" "$target/$path"
        fi
    done
}
export -f handle_client
