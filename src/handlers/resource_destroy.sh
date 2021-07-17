#!/usr/bin/env bash

handle_resource_destroy() {
    local resource="$1"
    local id="$2"

    local statement
    statement="$(sql_destroy_statement "$resource" "$id")"

    echo "st: $statement" >> /tmp/pog

    local object
    object="$(sqlite3 "$resource" ".mode json" "$statement" 2>/tmp/shibaerr)"

    echo "ob: $object" >> /tmp/pog

    local status="$?"

    object="${object#?}"
    object="${object%?}"

    if [[ $status -ne 0 ]]; then
        local error
        error="$(cat /tmp/shibaerr)"
        send_response_bad_request "${error#Error: }"
    fi

    send_response_ok "$object"
    log_handler_resource_destroy "$id"
}
export -f handle_resource_destroy
