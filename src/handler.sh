#!/usr/bin/env bash

# TODO: this
parse_object() {    
    while IFS= read -r line; do
        local -n reference="${1}"
        reference="$line"
        # TODO: error checking
        shift
    done
}
export -f parse_object


# TODO: this
parse_endpoints() {
    local -n array="$1"
    while IFS= read -r line; do
        [[ -z $line ]] && continue
        array+=("$line")
    done
}
export -f parse_endpoints


read_headers() {
    local -n array="$1"
    while recv2 line; do
        [[ -z $line ]] && break
        array+=("$line")
    done
}
export -f read_headers


quit() {
    printlog
    exit
}
export -f quit



handle_client() {
    REQUEST_ID="${BASHPID}"
    export REQUEST_ID
    
    set -o nounset
    # set -o xtrace
    set -o pipefail


    # # ///////////////
    # start_ts="$(date +%s%N | cut -b7-13)"
    # # ///////////////
    # # /////////////////////
    # end_ts="$(date +%s%N | cut -b7-13)"
    # >&2 echo "end:"
    # >&2 echo "$((end_ts - start_ts))"
    # # /////////////////////


    
    IFS=$'\n' read -d '' -ra STATIC_FILES <<< "$SHIBA_STATIC_FILES"
    IFS=$'\n' read -d '' -ra STATIC_DIRECTORIES <<< "$SHIBA_STATIC_DIRECTORIES"
    IFS=$'\n' read -d '' -ra COMMANDS <<< "$SHIBA_COMMANDS"
    IFS=$'\n' read -d '' -ra PROXIES <<< "$SHIBA_PROXIES"
    IFS=$'\n' read -d '' -ra RESOURCES <<< "$SHIBA_RESOURCES"


    # TODO: replace recv subshell
    read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION <<< "$(recv)"
    if [[ -z $REQUEST_METHOD ]]; then
        send_response_bad_request "no request method in http request header"
        log "REQUEST_NO_METHOD"
        quit
    fi
    if [[ -z $REQUEST_URI ]]; then
        send_response_bad_request "no uri in http request header"
        log "REQUEST_NO_URI"
        quit
    fi
    if [[ -z $REQUEST_HTTP_VERSION ]]; then
        send_response_bad_request "no http version in http request header"
        log "REQUEST_NO_HTTP_VERSION"
        quit
    fi

    REQUEST_URI="${REQUEST_URI//%20/ }"

    log "REQUEST_METHOD" "$REQUEST_METHOD"
    log "REQUEST_URI" "$REQUEST_URI"


    read_headers REQUEST_HEADERS    
    for header in "${REQUEST_HEADERS[@]}"; do  
        if [[ ${header} =~ ^([^:]+):[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            # log "REQUEST_HEADER_KEY" "${key}"
            # log "REQUEST_HEADER_VALUE" "${value}"
            [[ ${key} =~ [Cc]ontent-[Ll]ength ]] && CONTENT_LENGTH="${value}"
        fi
    done

    # TODO: something with this
    DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
    RESPONSE_HEADERS=(
        "Date: $DATE"
        "Expires: $DATE"
        "Server: shiba/$SHIBA_VERSION"
        "Access-Control-Allow-Origin: *"
        "Access-Control-Allow-Methods: OPTIONS, GET, POST, PUT, DELETE"
        "Access-Control-Allow-Headers: *"
    )

    for entry in "${STATIC_FILES[@]}"; do
        IFS='|' read -r endpoint target <<< "${entry}"

        regex="^${endpoint}$"
        if [[ $REQUEST_URI =~ $regex ]]; then
            log "REGEX_MATCH" "$regex"
            log "ENDPOINT_MATCH" "$endpoint"
            if [[ $REQUEST_METHOD != GET ]]; then
                send_response_method_not_allowed "$REQUEST_METHOD"
                quit
            fi

            handle_static_file "$target"
            quit
        fi
    done

    for entry in "${STATIC_DIRECTORIES[@]}"; do
        IFS='|' read -r endpoint directory <<< "${entry}"

        regex="^${endpoint}(.+)$"
        if [[ $REQUEST_URI =~ $regex ]]; then
            if [[ $REQUEST_METHOD != GET ]]; then
                send_response_method_not_allowed "$REQUEST_METHOD"
                quit
            fi

            file="$directory${BASH_REMATCH[1]}"
            log "REGEX_MATCH" "$regex"
            log "ENDPOINT_MATCH" "$endpoint"

            handle_static_file "$file"
            quit
        fi
    done

    for entry in "${COMMANDS[@]}"; do
        IFS='|' read -r endpoint command <<< "${entry}"

        regex="^$(sed 's|{[^}]*}|([^/]+)|g' <<< "$endpoint")$"
        if [[ $REQUEST_URI =~ $regex ]]; then
            log "REGEX_MATCH" "$regex"
            log "ENDPOINT_MATCH" "$endpoint"

            handle_command "${command}" "${BASH_REMATCH[@]:1}"
            quit
        fi
    done

    for entry in "${PROXIES[@]}"; do
        IFS='|' read -r endpoint server <<< "${entry}"

        # TODO: something about the trailing slashes
        regex="^$endpoint(/.*)?$"

        if [[ $REQUEST_URI =~ $regex ]]; then
            log "REGEX_MATCH" "$regex"
            log "ENDPOINT_MATCH" "$endpoint"

            url="$server${BASH_REMATCH[1]:-/}"
            handle_proxy "${url}"
            quit
        fi
    done

    for entry in "${RESOURCES[@]}"; do
        IFS='|' read -r endpoint resource <<< "${entry}"

        regex="^${endpoint}/?$"
        detail_regex="^${endpoint}/([^/]+)/?$"

        # TODO: replace id with custom key field name if present
        # send 404 when resource does not exist
        if [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log "REGEX_MATCH" "$regex"
            log "ENDPOINT_MATCH" "$endpoint"
            handle_resource_list "$resource"
            quit
        elif [[ $REQUEST_METHOD == "POST" ]] && [[ $REQUEST_URI =~ $regex ]]; then
            log "REGEX_MATCH" "$regex"
            log "ENDPOINT_MATCH" "$endpoint"
            handle_resource_create "$resource"
            quit
        elif [[ $REQUEST_METHOD == "GET" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            log "REGEX_MATCH" "$detail_regex"
            log "ENDPOINT_MATCH" "$endpoint/{id}"
            handle_resource_retrieve "$resource" "${id}"
            quit
        elif [[ $REQUEST_METHOD == "PUT" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            log "REGEX_MATCH" "$detail_regex"
            log "ENDPOINT_MATCH" "$endpoint/{id}"
            handle_resource_update "$resource" "${id}"
            quit
        elif [[ $REQUEST_METHOD == "DELETE" ]] && [[ $REQUEST_URI =~ $detail_regex ]]; then
            id="${BASH_REMATCH[1]}"
            log "REGEX_MATCH" "$detail_regex"
            log "ENDPOINT_MATCH" "$endpoint/{id}"
            handle_resource_destroy "$resource" "${id}"
            quit
        fi
    done

    log "NO_MATCH"
    send_response_not_found
    printlog
}
export -f handle_client
