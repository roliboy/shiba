#!/usr/bin/env bash

# TODO: 404 if file does not exist
handle_static_file() {
    file="$1"
    RESPONSE_HEADERS+=("Content-Length: $(stat --printf='%s' "$file")")
    RESPONSE_HEADERS+=("Content-Type: application/png")
    
    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    send_file "$file"
}
export -f handle_static_file

# handle_static_directory() {
#     directory="$1"
#     resource="$2"

#     RESPONSE_HEADERS+=("POG-Content-Directory: $directory")
#     RESPONSE_HEADERS+=("POG-Content-Resource: $resource")

#     RESPONSE_HEADERS+=("Content-Length: 3")
#     RESPONSE_HEADERS+=("Content-Type: text/html")
    
#     send "HTTP/1.0 200 OK"
#     for i in "${RESPONSE_HEADERS[@]}"; do
#         send "$i"
#     done
#     send

#     send "lel"
# }
# export -f handle_static_directory
