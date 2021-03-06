#!/usr/bin/env bash

handle_resource_create() {
    local resource="$1"

    if [[ -z ${CONTENT_LENGTH+x} ]]; then
        send_response_length_required
        quit
    fi

    if ! body="$(head -c "$CONTENT_LENGTH" | jq -c 2>/dev/null)"; then
        send_response_bad_request "could not parse request body"
        quit
    fi

    local statement
    statement="$(sql_create_statement "$resource" "$body")"


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

    send_response_created "$object"
    
    local idfield="$(sql_get_id_field "$resource")"
    local idval="$(jq ".\"$idfield\"" <<< "${object}")"
    
    log "HADNLER_RESOURCE_CREATE_SUCCESS" "$idfield" "$idval"
    log "SQL_QUERY" "$statement"
}
export -f handle_resource_create
