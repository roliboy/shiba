#!/usr/bin/env bash

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}
export -f trim

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
    if [[ -z $REQUEST_METHOD ]]; then
        send_response_bad_request "no request method in http request header"
        exit
    fi
    if [[ -z $REQUEST_URI ]]; then
        send_response_bad_request "no uri in http request header"
        exit
    fi
    if [[ -z $REQUEST_HTTP_VERSION ]]; then
        send_response_bad_request "no http version in http request header"
        exit
    fi

    log "REQUEST_METHOD" "$REQUEST_METHOD"
    log "REQUEST_URI" "$REQUEST_URI"

    # TODO: name reference
    declare -A _REQUEST_HEADERS
    REQUEST_HEADERS=()
    while line="$(recv)"; do
        [ -z "$line" ] && break
        REQUEST_HEADERS+=("$line")
        # TODO: method for parsing headers
        IFS=':' read -ra content <<< "$line"
        header="${content[0]}"
        value="$(trim "${content[1]}")"
        _REQUEST_HEADERS[$header]="$value"
        log_request_header "${header} => $value"
    done

    CONTENT_LENGTH="${_REQUEST_HEADERS[Content-Length]}"

    DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
    RESPONSE_HEADERS=(
        "Date: $DATE"
        "Expires: $DATE"
        "Server: shiba"
        "Access-Control-Allow-Origin: *"
        "Access-Control-Allow-Methods: OPTIONS, GET, POST, PUT, DELETE"
        "Access-Control-Allow-Headers: *"
    )

#     declare -A STATUS_CODES=(
#         [200]="OK",
#         [404]="Not Found"
#     )

    parse_endpoints STATIC_FILES <<< "$SHIBA_STATIC_FILES"
    parse_endpoints STATIC_DIRECTORIES <<< "$SHIBA_STATIC_DIRECTORIES"
    parse_endpoints COMMANDS <<< "$SHIBA_COMMANDS"
    parse_endpoints PROXIES <<< "$SHIBA_PROXIES"
    parse_endpoints RESOURCES <<< "$SHIBA_RESOURCES"

    for entry in "${STATIC_FILES[@]}"; do
        IFS=$'\n' read -rd '' endpoint file <<< "$(split_object "$entry")"

        regex="^${endpoint}$"
        if [[ $REQUEST_URI =~ $regex ]]; then
            if [[ $REQUEST_METHOD != GET ]]; then
                send_response_method_not_allowed "$REQUEST_METHOD"
                return
            fi
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            handle_static_file
        fi
    done

    for entry in "${STATIC_DIRECTORIES[@]}"; do
        IFS=$'\n' read -rd '' endpoint directory <<< "$(split_object "$entry")"

        regex="^${endpoint}(.+)$"
        if [[ $REQUEST_URI =~ $regex ]]; then
            if [[ $REQUEST_METHOD != GET ]]; then
                send_response_method_not_allowed "$REQUEST_METHOD"
                return
            fi
            file="$directory${BASH_REMATCH[1]}"
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            handle_static_file
        fi
    done

    for entry in "${COMMANDS[@]}"; do
        IFS=$'\n' read -rd '' endpoint command <<< "$(split_object "$entry")"

        regex="^$(echo "$endpoint" | sed 's|{[^}]*}|([^/]+)|g')$"
        if [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            handle_command "$command" "${BASH_REMATCH[@]:1}"
        fi
    done

    for entry in "${PROXIES[@]}"; do
        [[ -z $entry ]] && continue
        IFS=$'\n' read -rd '' endpoint server <<< "$(split_object "$entry")"

        # TODO: something about the trailing slashes
        regex="^$endpoint(/.*)?$"

        # TODO: handle other methods
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log_regex_match "$regex"
            log_endpoint_match "$endpoint"
            url="$server${BASH_REMATCH[1]:-/}"
            handle_proxy
        fi
    done

    for entry in "${RESOURCES[@]}"; do
        IFS=$'\n' read -rd '' endpoint resource <<< "$(split_object "$entry")"

        regex="^${endpoint}/?$"
        detail_regex="^${endpoint}/([^/]+)/?$"

        # TODO: replace id with custom key field name if present
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            log "ENDPOINT_MATCH_REGEX" "$detail_regex"
            log "ENDPOINT_MATCH" "$endpoint/{id}"
            handle_resource_retrieve "$resource" "${id//%20/ }"
        elif [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log "ENDPOINT_MATCH_REGEX" "$regex"
            log "ENDPOINT_MATCH" "$endpoint"
            handle_resource_list "$resource"
        elif [[ $REQUEST_METHOD == "POST" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log "ENDPOINT_MATCH_REGEX" "$regex"
            log "ENDPOINT_MATCH" "$endpoint"
            handle_resource_create "$resource"
        elif [[ $REQUEST_METHOD == "PUT" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            log "ENDPOINT_MATCH_REGEX" "$detail_regex"
            log "ENDPOINT_MATCH" "$endpoint/{id}"
            handle_resource_update "$resource" "${id//%20/ }"
        elif [[ $REQUEST_METHOD == "DELETE" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            log "ENDPOINT_MATCH_REGEX" "$detail_regex"
            log "ENDPOINT_MATCH" "$endpoint/{id}"
            handle_resource_destroy "$resource" "${id//%20/ }"
        fi
    done
}
export -f handle_client
