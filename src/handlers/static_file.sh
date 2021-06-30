#!/usr/bin/env bash

handle_static_file() {
    file="$1"
    if [[ -f $file ]]; then    
        RESPONSE_HEADERS+=("Content-Length: $(stat --printf='%s' "$file")")
        RESPONSE_HEADERS+=("Content-Type: $(file -b --mime-type "$file")")
        
        send "HTTP/1.0 200 OK"
        for i in "${RESPONSE_HEADERS[@]}"; do
            send "$i"
        done
        send

        send_file "$file"
        log_handler_static_file_sent "$file"
    else
        message="file not found"
        RESPONSE_HEADERS+=("Content-Length: ${#message}")
        RESPONSE_HEADERS+=("Content-Type: text/html")

        send "HTTP/1.0 404 File not found"
        for i in "${RESPONSE_HEADERS[@]}"; do
            send "$i"
        done
        send

        send "$message"
        log_handler_static_file_not_found "$file"
    fi
}
export -f handle_static_file
