#!/usr/bin/env bash

# DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
# declare -a RESPONSE_HEADERS=(
#     "Date: $DATE"
#     "Expires: $DATE"
#     "Server: shiba"
#     "Access-Control-Allow-Origin: *"
#     "Access-Control-Allow-Methods: OPTIONS, GET, POST, PUT, DELETE"
#     "Access-Control-Allow-Headers: *"
# )
# export RESPONSE_HEADERS

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
    local file="$1"

    RESPONSE_HEADERS+=("Content-Length: $(stat --printf='%s' "$file")")
    RESPONSE_HEADERS+=("Content-Type: $(file -b --mime-type "$file")")

    send "HTTP/1.0 200 OK"
    send_headers
    send_file "$file"
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
export -f send_response_method_not_allowed


send_response_ok() {
    response="$1"

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 200 OK"
    send_headers
    send "$response"
}
export -f send_response_ok


send_response_not_found() {
    response='{"status": "requested resource does not exist"}'

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 404 Not Found"
    send_headers
    send "$response"
}
export -f send_response_not_found


send_response_no_content() {
    response="$1"

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 204 No Content"
    send_headers
    send "$response"
}
export -f send_response_no_content

send_response_created() {
    response="$1"

    RESPONSE_HEADERS+=("Content-Length: ${#response}")
    RESPONSE_HEADERS+=("Content-Type: application/json")

    send "HTTP/1.0 201 Created"
    send_headers
    send "$response"
}
export -f send_response_created
