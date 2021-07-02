#!/usr/bin/env bash

# TODO: 404 if file does not exist
handle_command() {
    command="$1"

    CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"
    
    IFS= read -d '@' -rn "$CONTENT_LENGTH" stdin
    stdin=${stdin%%$'\r'}
    log "STDIN: $stdin"
    # stdin="$(</dev/stdin)"
    # stdin="$(cat)"
    shift

    # TODO: make this less spaghett
    read -ra parts <<< "$command"
    command="${parts[0]}"
    arguments=()

    if [[ ${#parts[@]} -gt 1 ]]; then
        arguments=("${parts[*]:1}")
    fi

    arguments+=("$@")

    
    log "COMMAND: $command"
    log "ARGUMENTS: ${arguments[*]}"
    log "STDIN $stdin"

    # TODO: prepend ./ when name is not fully qualified?

    if [[ ${#arguments[@]} == 0 ]]; then
        result="$("$command" <<< "$stdin")"
    else
        log "EXEC: $command ${arguments[*]} | $stdin"
        result="$("$command" "${arguments[@]}" <<< "$stdin")"
    fi

    log "RESULT: $result"


    # TODO: respond with 500 internal server error if command fails
    RESPONSE_HEADERS+=("Content-Length: ${#result}")
    # TODO: set content-type to application/json if the result is valid json?
    RESPONSE_HEADERS+=("Content-Type: text/plain")
    
    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    # TODO: breaks when too many newlines in result
    send "$result"
    log_handler_command_response "$command" "${arguments[*]}"
}
export -f handle_command
