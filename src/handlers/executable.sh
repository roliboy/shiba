#!/usr/bin/env bash

# TODO: 404 if file does not exist
handle_executable() {
    executable="$1"
    shift

    CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"

    read -rn "$CONTENT_LENGTH" body
    body=${body%%$'\r'}
    log "BODY: $body"

    # TODO: pass body to stdin
    # TODO: prepend ./ when name is not fully qualified
    result="$("./$executable" "$*" <<< "$body")"

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
export -f handle_executable
