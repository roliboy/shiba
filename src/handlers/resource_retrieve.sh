#!/usr/bin/env bash

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
