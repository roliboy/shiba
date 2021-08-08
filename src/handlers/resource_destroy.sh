#!/usr/bin/env bash

handle_resource_destroy() {
    local resource="$1"
    local id="$2"

    local statement
    statement="$(sql_destroy_statement "$resource" "$id")"


    local object
    object="$(sqlite3 "$resource" ".mode json" "$statement" 2>/tmp/shibaerr)"


    local status="$?"

    object="${object#?}"
    object="${object%?}"

    if [[ $status -ne 0 ]]; then
        local error
        error="$(cat /tmp/shibaerr)"
        send_response_bad_request "${error#Error: }"
    fi

    send_response_ok "$object"
    
    local idfield="$(sql_get_id_field "$resource")"
    local idval="$(jq ".\"$idfield\"" <<< "${object}")"

    log "HADNLER_RESOURCE_DESTROY_SUCCESS" "$idfield" "$idval"
    log "SQL_QUERY" "$statement"
}
export -f handle_resource_destroy
