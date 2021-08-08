#!/usr/bin/env bash

handle_resource_update() {
    local resource="$1"
    local id="$2"

    if [[ -z $CONTENT_LENGTH ]]; then
        send_response_length_required
        quit
    fi

    if ! body="$(head -c "$CONTENT_LENGTH" | jq -c 2>/dev/null)"; then
        send_response_bad_request "could not parse request body"
        quit
    fi

    local statement
    statement="$(sql_update_statement "$resource" "$id" "$body")"


    local object
    object="$(sqlite3 "$resource" ".mode json" "$statement" 2>/tmp/shibaerr)"


    local status="$?"

    object="${object#?}"
    object="${object%?}"

    echo "ob: $object" >> /tmp/pog

    if [[ $status -ne 0 ]]; then
        local error
        error="$(cat /tmp/shibaerr)"
        send_response_bad_request "${error#Error: }"
    fi

    send_response_ok "$object"
    
    local idfield="$(sql_get_id_field "$resource")"
    local idval="$(jq ".\"$idfield\"" <<< "${object}")"

    log "HADNLER_RESOURCE_UPDATE_SUCCESS" "$idfield" "$idval"
    log "SQL_QUERY" "$statement"
}
export -f handle_resource_update
