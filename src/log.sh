#!/usr/bin/env bash

printlog() {
    while read -r line; do
        event="$(cut -d' ' -f1 <<< "$line")"
        value="$(cut -d' ' -f2- <<< "$line")"
        case "$event" in
            RECEIVED)
                ;;
            SENT)
                ;;
            REQUEST_METHOD)
                echo -ne "${GREEN}$value${NC} "
                ;;
            REQUEST_URI)
                echo -ne "${BLUE}$value:${NC}\n"
                ;;
            REGEX_MATCH)
                echo -ne "    ${CYAN}matched${NC} $value -> "
                ;;
            ENDPOINT_MATCH)
                echo -ne "${YELLOW}$value${NC}\n"
                ;;
            STATIC_FILE_SENT)
                echo -ne "    ${CYAN}code${NC} ${GREEN}200 OK${NC}\n"
                echo -ne "    ${CYAN}file${NC} $value ${GREEN}sent${NC}\n"
                ;;
            STATIC_FILE_NOT_FOUND)
                echo -ne "    ${CYAN}code${NC} ${RED}404 Not Found${NC}\n"
                echo -ne "    ${CYAN}file${NC} $value ${RED}not found${NC}\n"
                ;;
        esac
    done < /tmp/shibalog
}

startlog() {
    echo -n '' > /tmp/shibalog
}
export -f startlog

log() {
    echo "$*" >> /tmp/shibalog
}
export -f log

log_received_data() {
    log "RECEIVED $*"
}
export -f log_received_data

log_sent_data() {
    log "SENT $*"
}
export -f log_sent_data

log_request_method() {
    log "REQUEST_METHOD $*"
}
export -f log_request_method

log_request_uri() {
    log "REQUEST_URI $*"
}
export -f log_request_uri

log_request_header() {
    log "REQUEST_HEADER $*"
}
export -f log_request_header

log_response_header() {
    log "RESPONSE_HEADER $*"
}
export -f log_response_header

log_endpoint_match() {
    log "ENDPOINT_MATCH $*"
}
export -f log_endpoint_match

log_regex_match() {
    log "REGEX_MATCH $*"
}
export -f log_regex_match

log_handler_static_file_sent() {
    log "STATIC_FILE_SENT $*"
}
export -f log_handler_static_file_sent

log_handler_static_file_not_found() {
    log "STATIC_FILE_NOT_FOUND $*"
}
export -f log_handler_static_file_not_found
