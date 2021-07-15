#!/usr/bin/env bash

handle_resource_retrieve() {
    element="$(jq -c ".[] | select(.id == $id)" < "$resource")"

    send_response_ok "$element"
    log_handler_resource_retrieve "$id"
}
export -f handle_resource_retrieve
