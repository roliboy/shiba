#!/usr/bin/env bash

handle_static_file() {
    if [[ -f $file ]]; then
        send_response_file "$file"
        log_handler_static_file_sent "$file"
    else
        send_response_not_found
        log_handler_static_file_not_found "$file"
    fi
}
export -f handle_static_file
