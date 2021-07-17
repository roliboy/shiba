#!/usr/bin/env bash

# TODO: clean this up
# 400
send_response_bad_request() {
    local content="{\"status\":400,\"error\":\"Bad Request\",\"message\":\"$1\"}"
    send_response_string "$STATUS_BAD_REQUEST" "$content" "application/json"
}
export -f send_response_bad_request

# 404
send_response_not_found() {
    # TODO: resource name in message
    local content='{"status":404,"error":"Not Found","message":"requested resource does not exist"}'
    send_response_string "$STATUS_NOT_FOUND" "$content" "application/json"
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
