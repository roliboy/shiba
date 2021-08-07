#!/usr/bin/env bash

# 200
# TODO: merge this with static file handler
send_response_ok() {
    send_response "$STATUS_OK" "${#1}" "${2:-application/json}" <<< "$1"
}
export -f send_response_ok

# 201
send_response_created() {
    send_response "$STATUS_CREATED" "$1" "application/json"
}
export -f send_response_created

# 204
send_response_no_content() {
    send_response "$STATUS_NO_CONTENT" "$1" "application/json"
}
export -f send_response_no_content
