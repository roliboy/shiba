#!/usr/bin/env bash

handle_resource_list() {
    local resource="$1"

    local statement
    # statement="$(sql_list_statement "$resource")"
    statement="$(sql_list_statement)"

    log "SQL_QUERY" "$statement"

    # TODO: pipe directly?
    local objects
    objects="$(sqlite3 "$resource" ".mode json" "$statement" 2>/tmp/shibaerr)"

    local status="$?"

    if [[ $status -ne 0 ]]; then
        local error
        error="$(cat /tmp/shibaerr)"
        send_response_bad_request "${error#Error: }"
    fi

    send_response_ok "${objects//$'\n'}"
    log_handler_resource_list "420"
}
export -f handle_resource_list
