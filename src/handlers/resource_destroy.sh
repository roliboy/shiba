#!/usr/bin/env bash

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
