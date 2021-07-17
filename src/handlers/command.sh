#!/usr/bin/env bash

handle_command() {
    local command="$1"
    local args=("${@:2}")

    read -ra parts <<< "$command"
    command="${parts[0]}"
    arguments=("${parts[@]:1}" "${args[@]}")
    
    SHIBA_REQUEST_METHOD="$REQUEST_METHOD"
    export SHIBA_REQUEST_METHOD

#     TODO: binary support?
    if [[ ${#arguments[@]} -eq 0 ]]; then
        if [[ -n $CONTENT_LENGTH ]]; then
            result="$(head -c "$CONTENT_LENGTH" | "$command")"
        else
            result="$("$command" <<< "")"
        fi
    else
        if [[ -n $CONTENT_LENGTH ]]; then
            result="$(head -c "$CONTENT_LENGTH" | "$command" "${arguments[@]}")"
        else
            result="$("$command" "${arguments[@]}" <<< "")"
        fi
    fi

    exit_code="$?"
    if [[ $exit_code -eq 0 ]]; then
        send_response_ok "$result" "text/plain"
    else
        send_response_internal_server_error
    fi

    log_handler_command_response "$command" "${arguments[*]}"
}
export -f handle_command
