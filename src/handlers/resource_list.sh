#!/usr/bin/env bash

handle_resource_list() {
    resource_file="$1"
    
    RESPONSE_HEADERS+=("Content-Length: $(stat --printf='%s' "$resource_file")")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    elements="$(jq length "$resource_file")"

    send_file "$resource_file"
    log_handler_resource_list "$elements"
}
export -f handle_resource_list
