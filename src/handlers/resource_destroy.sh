#!/usr/bin/env bash

handle_resource_destroy() {
    data="$(cat "$resource")"
    element="$(jq -c ".[] | select(.id == $id)" <<< "$data")"

    jq -c "map(select(.id != $id))" <<< "$data" > "$resource"

    send_response_ok "$element"
    log_handler_resource_destroy "$id"
}
export -f handle_resource_destroy
