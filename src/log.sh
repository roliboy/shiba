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
                echo -ne "    ${GREEN}matched${NC} $value -> "
                ;;
            ENDPOINT_MATCH)
                echo -ne "${YELLOW}$value${NC}\n"
                ;;
            *)
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
