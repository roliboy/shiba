#!/usr/bin/env bash

handle_resource_list() {
    send_response_file "$resource"
    log_handler_resource_list "$(jq length "$resource")"
}
export -f handle_resource_list
