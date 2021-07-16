#!/usr/bin/env bash

send() {
#     log_sent_data "$*"
    printf '%s\r\n' "$*"
}
export -f send

send_file() {
#     log_sent_data "file $1"
    cat "$1"
}
export -f send_file

send_headers() {
    for header in "${RESPONSE_HEADERS[@]}"; do
        send "$header"
    done
    send
}
export -f send_headers

send_response_string() {
    local status="$1"
    local content_type="$2"
    local response="$3"

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
