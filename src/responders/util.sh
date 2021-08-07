#!/usr/bin/env bash

send_headers() {
    for header in "${RESPONSE_HEADERS[@]}"; do
        send "$header"
    done
    send
}
export -f send_headers

send_response() {
    local status="$1"
    local content_length="$2"
    local content_type="$3"

    RESPONSE_HEADERS+=("Content-Length: ${content_length}")
    RESPONSE_HEADERS+=("Content-Type: ${content_type}")

    send "HTTP/1.0 ${status}"
    send_headers
    log "RESPONSE_CODE" "${status}"
    cat
}
export -f send_response
