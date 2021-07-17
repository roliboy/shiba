#!/usr/bin/env bash

# TODO: clean this up
# 400
send_response_bad_request() {
    local status="$1"
    local content

    shift
    if [[ $# -gt 0 ]]; then
        local errors=""
        for error in "$@"; do
            errors="$errors\"$error\","
        done
        content="{\"status\":\"$status\",\"errors\":[${errors::-1}]}"
    else
        content="{\"status\":\"$status\"}"
    fi

    send_response_string "$STATUS_BAD_REQUEST" "application/json" "$content"
}
export -f send_response_bad_request

# 404
send_response_not_found() {
    local content='{"status": "requested resource does not exist"}'
    send_response_string "$STATUS_NOT_FOUND" "application/json" "$content"
}
export -f send_response_not_found

# 405
send_response_method_not_allowed() {
    local content="{\"status\": \"method $1 not allowed\"}"
    send_response_string "$STATUS_METHOD_NOT_ALLOWED" "$content" "application/json"
}
export -f send_response_method_not_allowed

# 411
send_response_length_required() {
    local content='{"status": "missing content-length header"}'
    send_response_string "$STATUS_LENGTH_REQUIRED" "$content" "application/json"
}
export -f send_response_length_required

# 500
send_response_internal_server_error() {
    local content='{"status": "an error occured while proccessing the request"}'
    send_response_string "$STATUS_INTERNAL_SERVER_ERROR" "$content" "application/json"
}
export -f send_response_internal_server_error
