#!/usr/bin/env bash

error() {
    echo -e "${RED}ERROR${NC}: $1"
    exit "${2:-1}"
}

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
                echo -ne "    ${CYAN}matched${NC}\n"
                echo -ne "        $value -> "
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
            PROXY_RESPONSE)
                read -r contentlength contenttype <<< "$value"
                echo -ne "    ${CYAN}code${NC} ${GREEN}200 OK${NC}\n"
                echo -ne "    ${CYAN}proxy${NC} responded with ${GREEN}$contentlength${NC} bytes of $contenttype\n"
                ;;
            COMMAND_RESPONSE)            
                read -r command arguments <<< "$value"
                echo -ne "    ${CYAN}code${NC} ${GREEN}200 OK${NC}\n"
                echo -ne "    ${CYAN}command${NC} ${MAGENTA}$command $arguments${NC} ran successfully\n"
                ;;
            RESOURCE_CREATE)
                read -r id <<< "$value"
                echo -ne "    ${CYAN}code${NC} ${GREEN}201 CREATED${NC}\n"
                echo -ne "    ${CYAN}created${NC} resource with id ${GREEN}$id${NC}\n"
                ;;
            RESOURCE_DESTROY)
                read -r id <<< "$value"
                echo -ne "    ${CYAN}code${NC} ${GREEN}200 OK${NC}\n"
                echo -ne "    ${CYAN}destroyed${NC} resource with id ${GREEN}$id${NC}\n"
                ;;
            RESOURCE_LIST)
                read -r length <<< "$value"
                echo -ne "    ${CYAN}code${NC} ${GREEN}200 OK${NC}\n"
                echo -ne "    ${CYAN}listed${NC} ${GREEN}$length${NC} elements\n"
                ;;
            RESOURCE_RETRIEVE)
                read -r id <<< "$value"
                echo -ne "    ${CYAN}code${NC} ${GREEN}200 OK${NC}\n"
                echo -ne "    ${CYAN}retrieved${NC} resource with id ${GREEN}$id${NC}\n"
                ;;
            RESOURCE_UPDATE)
                read -r id <<< "$value"
                echo -ne "    ${CYAN}code${NC} ${GREEN}200 OK${NC}\n"
                echo -ne "    ${CYAN}updated${NC} resource with id ${GREEN}$id${NC}\n"
                ;;
            SQL_QUERY)
                [[ $SHIBA_LOG_QUERIES = true ]] || continue

                echo "$value"
                
                echo -ne "    ${CYAN}sql query${NC}\n"
                while IFS= read -r line; do
                    echo -ne "        $line\n"
                done <<< "$(sql_syntax_highlight "$value")"
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

log_handler_proxy_response() {
    log "PROXY_RESPONSE $*"
}
export -f log_handler_proxy_response

log_handler_command_response() {
    log "COMMAND_RESPONSE $*"
}
export -f log_handler_command_response

log_handler_resource_create() {
    log "RESOURCE_CREATE $*"
}
export -f log_handler_resource_create

log_handler_resource_destroy() {
    log "RESOURCE_DESTROY $*"
}
export -f log_handler_resource_destroy

log_handler_resource_list() {
    log "RESOURCE_LIST $*"
}
export -f log_handler_resource_list

log_handler_resource_retrieve() {
    log "RESOURCE_RETRIEVE $*"
}
export -f log_handler_resource_retrieve

log_handler_resource_update() {
    log "RESOURCE_UPDATE $*"
}
export -f log_handler_resource_update
