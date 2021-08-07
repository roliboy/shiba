#!/usr/bin/env bash

printlog() {
    while read -r line; do
        event="$(cut -d' ' -f1 <<< "$line")"
        value="$(cut -d' ' -f2- <<< "$line")"
        case "$event" in
            REQUEST_NO_METHOD)
                >&2 echo -ne "${RED}bad request:${CLEAR} no method in request header\n"
                ;;
            REQUEST_NO_URI)
                >&2 echo -ne "${RED}bad request:${CLEAR} no URI in request header\n"
                ;;
            REQUEST_NO_HTTP_VERSION)
                >&2 echo -ne "${RED}bad request:${CLEAR} no HTTP version in request header\n"
                ;;

            # SHIBA_LOG_REQUEST
            REQUEST_METHOD)
                >&2 echo -ne "${GREEN}$value${CLEAR} "
                ;;
            REQUEST_URI)
                >&2 echo -ne "${BLUE}$value:${CLEAR}\n"
                ;;

            # SHIBA_LOG_ENDPOINT_MATCH
            ENDPOINT_MATCH_REGEX)
                [[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] || continue
                >&2 printf "  ${CYAN}%s${CLEAR}\n" "matched"
                >&2 printf "    %s -> "            "$value"
                ;;
            ENDPOINT_MATCH)
                [[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] || continue
                >&2 printf "${YELLOW}%s${CLEAR}\n" "$value"
                ;;
            NO_ENDPOINT_MATCH)
                [[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] || continue
                >&2 printf "  ${CYAN}%s${CLEAR}\n"  "matched"
                >&2 printf "    ${RED}%s${CLEAR}\n" "requested uri didn't match any route"
                ;;

            # RESPONSE STATUS
            RESPONSE_STATUS)
                >&2 echo -ne "  ${CYAN}response${CLEAR}\n"
                if [[ ${value::1} = 2 ]]; then
                    >&2 echo -ne "        ${GREEN}$value${CLEAR}\n"
                elif [[ ${value::1} = 4 ]]; then
                    >&2 echo -ne "        ${RED}$value${CLEAR}\n"
                else
                    >&2 echo -ne "        $value\n"
                fi
                ;;

            # TODO: module/handler status log flag
            # STATIC FILE HANDLER
            HANDLER_STATIC_FILE_SENT)
                read -r filename filesize filetype <<< "${value}"
                >&2 echo -ne "    ${CYAN}action${CLEAR}\n"
                >&2 echo -ne "        ${GREEN}sent${CLEAR} $filesize bytes of $filetype ($filename)\n"
                ;;
            HANDLER_STATIC_FILE_NOT_FOUND)
                >&2 echo -ne "    ${CYAN}action${CLEAR}\n"
                >&2 echo -ne "        ${RED}not found${CLEAR} ($fiename)\n"
                ;;
            
            # SHIBA_LOG_SQL_QUERY
            SQL_QUERY)
                [[ $SHIBA_LOG_SQL_QUERY = true ]] || continue
                echo -ne "    ${CYAN}sql query${CLEAR}\n"
                while IFS= read -r line; do
                    echo -ne "        $line\n"
                done <<< "$(sql_syntax_highlight "$value")"
                ;;
        esac
    done < "/tmp/shibalog$BASHPID"
    rm "/tmp/shibalog$BASHPID"
}
export -f printlog

log() {
    echo "$*" >> "/tmp/shibalog$BASHPID"
}
export -f log
