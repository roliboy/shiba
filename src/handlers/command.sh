#!/usr/bin/env bash

handle_command() {
    # TODO: make this less spaghett
    read -ra parts <<< "$command"
    command="${parts[0]}"
    args=()

    if [[ ${#parts[@]} -gt 1 ]]; then
        args=("${parts[*]:1}")
    fi

    args+=("$arguments")

    SHIBA_REQUEST_METHOD="$REQUEST_METHOD"
    export SHIBA_REQUEST_METHOD

#     TODO: save to file?

    if [[ ${#args[@]} -eq 0 ]]; then
        if [[ -n $CONTENT_LENGTH ]]; then
            result="$(head -c "$CONTENT_LENGTH" | "$command")"
        else
            result="$("$command" <<< "")"
        fi
    else
        if [[ -n $CONTENT_LENGTH ]]; then
            result="$(head -c "$CONTENT_LENGTH" | "$command" "${args[@]}")"
        else
            result="$("$command" "${args[@]}" <<< "")"
        fi
    fi



    RESPONSE_HEADERS+=("Content-Length: ${#result}")
    # TODO: set content-type to application/json if the result is valid json?
    RESPONSE_HEADERS+=("Content-Type: text/plain")

    exit_code="$?"
    if [[ $exit_code -eq 0 ]]; then
        send "HTTP/1.0 200 OK"
    else
        send "HTTP/1.0 500 Internal Server Error"
    fi

    send_headers

    send "$result"
    log_handler_command_response "$command" "${arguments[*]}"
}
export -f handle_command
