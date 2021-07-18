#!/usr/bin/env bash

send_headers() {
    for header in "${RESPONSE_HEADERS[@]}"; do
        send "$header"
    done
    send
}
export -f send_headers

send_response_string() {
    local status="$1"
    local response="$2"
    local content_type="$3"

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: ${content_type}")

    send "HTTP/1.0 ${status}"
    send_headers
    send "$response"
}
export -f send_response_string


send_response_file() {
    local file="$1"

    RESPONSE_HEADERS+=("Content-Length: $(stat --printf='%s' "$file")")
    RESPONSE_HEADERS+=("Content-Type: $(file -b --mime-type "$file")")

    send "HTTP/1.0 200 OK"
    send_headers
    send_file "$file"
}
export -f send_response_file
