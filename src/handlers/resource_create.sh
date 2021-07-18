#!/usr/bin/env bash

handle_resource_create() {
    local resource="$1"

    if [[ -z $CONTENT_LENGTH ]]; then
        send_response_length_required
        return
    fi

    if ! body="$(head -c "$CONTENT_LENGTH" | jq -c 2>/dev/null)"; then
        send_response_bad_request "could not parse request body"
        return
    fi

    local statement
    statement="$(sql_create_statement "$resource" "$body")"

    log "SQL_QUERY" "$statement"

    local object
    object="$(sqlite3 "$resource" ".mode json" "$statement" 2>/tmp/shibaerr)"

    local status="$?"

    object="${object#?}"
    object="${object%?}"

    # echo "$object" >> /tmp/pog

    if [[ $status -ne 0 ]]; then
        local error
        error="$(cat /tmp/shibaerr)"
        send_response_bad_request "${error#Error: }"
    fi

    send_response_created "$object"
    log_handler_resource_create "-1"
}
export -f handle_resource_create
