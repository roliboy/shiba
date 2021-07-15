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
