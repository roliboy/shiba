#!/usr/bin/env bash

# TODO: 404 if file does not exist
handle_command() {
    command="$1"
    shift

    CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"

    # TODO: something about this
    read -d'@' -rn "$CONTENT_LENGTH" body
    body=${body%%$'\r'}
    log "BODY: $body"

    read -ra parts <<< "$command"

    log "COMMAND: ${parts[0]}"
    log "ARGUMENTS: ${parts[*]:1}"

    # TODO: prepend ./ when name is not fully qualified
    # result="$("$command" "$*" <<< "$body")"
    # TODO: no "$*" when the endpoint takes no path variables
    result="$("${parts[0]}" "${parts[@]:1}" <<< "$body")"
    # TODO: no arguments when command does not contain spaces?
    # result="$("${parts[0]}" "${parts[@]:1}" <<< "$body")"

    log "RESULT: $result"



    RESPONSE_HEADERS+=("Content-Length: ${#result}")
    # TODO: set content-type to application/json if the result is valid json?
    RESPONSE_HEADERS+=("Content-Type: text/html")
    
    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    # breaks when too many newlines in result
    send "$result"
}
export -f handle_command
