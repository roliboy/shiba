#!/usr/bin/env bash

handle_resource_list() {
    RESPONSE_HEADERS+=("Content-Length: $(stat --printf='%s' "$resource")")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    elements="$(jq length "$resource")"

    send_file "$resource"
    log_handler_resource_list "$elements"
}
export -f handle_resource_list
