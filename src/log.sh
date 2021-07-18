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

            # SHIBA_LOG_REQUEST
            REQUEST_METHOD)
                echo -ne "${GREEN}$value${NC} "
                ;;
            REQUEST_URI)
                echo -ne "${BLUE}$value:${NC}\n"
                ;;

            # SHIBA_LOG_ENDPOINT_MATCH
            ENDPOINT_MATCH_REGEX)
                [[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] || continue
                echo -ne "    ${CYAN}matched${NC}\n"
                echo -ne "        $value -> "
                ;;
            ENDPOINT_MATCH)
                [[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] || continue
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
            
            # SHIBA_LOG_SQL_QUERY
            SQL_QUERY)
                [[ $SHIBA_LOG_SQL_QUERY = true ]] || continue
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
