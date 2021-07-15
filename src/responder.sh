#!/usr/bin/env bash

DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
declare -a RESPONSE_HEADERS=(
    "Date: $DATE"
    "Expires: $DATE"
    "Server: shiba"
    "Access-Control-Allow-Origin: *"
    "Access-Control-Allow-Methods: OPTIONS, GET, POST, PUT, DELETE"
    "Access-Control-Allow-Headers: *"
)

send_response_string() {
    response="$1"

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 201 Created"
    send_headers
    send "$response"
}
export -f send_response_string

send_response_file() {
    :
}
export -f send_response_file



# TODO: something about status
send_response_bad_request() {
    local status="$1"
    shift

    if [[ $# -gt 0 ]]; then
        local errors=""
        for error in "$@"; do
            errors="$errors\"$error\","
        done
        local response="{\"status\":\"$status\",\"errors\":[${errors::-1}]}"
    else
        local response="{\"status\":\"$status\"}"
    fi

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 400 Bad Request"
    send_headers
    send "$response"
}
export -f send_response_bad_request

send_response_length_required() {
    response='{"status": "missing content-length header"}'

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 411 Length Required"
    send_headers
    send "$response"
}

# TODO: make this call generic responder
send_response_method_not_allowed() {
    response='{"status": "method not allowed"}'

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 405 Method Not Allowed"
    send_headers
    send "$response"
}


send_response_created() {
    response="$1"

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 201 Created"
    send_headers
    send "$response"
}
export -f send_response_created
