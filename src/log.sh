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
            REGEX_MATCH)
                [[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] || continue
                >&2 printf "  ${CYAN}%s${CLEAR}\n" "matched"
                >&2 printf "    %s -> "            "$value"
                ;;
            ENDPOINT_MATCH)
                [[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] || continue
                >&2 printf "${YELLOW}%s${CLEAR}\n" "$value"
                ;;
            NO_MATCH)
                [[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] || continue
                >&2 printf "  ${CYAN}%s${CLEAR}\n"  "matched"
                >&2 printf "    ${RED}%s${CLEAR}\n" "requested uri didn't match any route"
                ;;

            # RESPONSE STATUS
            RESPONSE_CODE)
                # >&2 echo "RESPONSE CODE: ${value}"
                [[ $SHIBA_LOG_RESPONSE_CODE = true ]] || continue
                >&2 printf "  ${CYAN}%s${CLEAR}\n" "response"
                if [[ ${value::1} = 2 ]]; then
                    >&2 printf "    ${GREEN}%s${CLEAR}\n" "$value"
                elif [[ ${value::1} = 4 ]]; then
                    >&2 printf "    ${RED}%s${CLEAR}\n" "$value"
                else
                    >&2 printf "    %s\n" "$value"
                fi
                ;;

            # STATIC FILE HANDLER
            HANDLER_STATIC_FILE_SENT)
                [[ $SHIBA_LOG_HANDLER_STATUS = true ]] || continue
                read -r filename filesize filetype <<< "${value}"
                >&2 printf "  ${CYAN}%s${CLEAR}\n" "stauts"
                # TODO: colors
                >&2 printf "    ${GREEN}%s${CLEAR} %s\n" "sent" "$filesize bytes of $filetype ($filename)"
                ;;
            HANDLER_STATIC_FILE_NOT_FOUND)
                [[ $SHIBA_LOG_HANDLER_STATUS = true ]] || continue
                >&2 printf "  ${CYAN}%s${CLEAR}\n" "stauts"
                # TODO: this
                >&2 printf "    ${RED}%s${CLEAR} %s\n" "not found" "($value)"
                ;;

            HANDLER_COMMAND_SUCCESS)
                [[ $SHIBA_LOG_HANDLER_STATUS = true ]] || continue
                read -ra parts <<< "${value}"
                >&2 printf "  ${CYAN}%s${CLEAR}\n" "stauts"
                # TODO: colors
                >&2 printf "    ${GREEN}%s${CLEAR} %s producing %d bytes of %s\n" "executed" "${parts[*]:2}" "${parts[0]}" "${parts[1]}"
                ;;

            HANDLER_COMMAND_ERROR)
                [[ $SHIBA_LOG_HANDLER_STATUS = true ]] || continue
                read -ra parts <<< "${value}"
                >&2 printf "  ${CYAN}%s${CLEAR}\n" "stauts"
                # TODO: colors
                >&2 printf "    ${RED}%s${CLEAR} %s with exit code %d\n" "failed" "${parts[*]:1}" "${parts[0]}"
                ;;

            HANDLER_PROXY_SUCCESS)
                [[ $SHIBA_LOG_HANDLER_STATUS = true ]] || continue
                read -ra parts <<< "${value}"
                >&2 printf "  ${CYAN}%s${CLEAR}\n" "stauts"
                # TODO: colors
                >&2 printf "    ${GREEN}%s${CLEAR} responded with %d bytes of %s\n" "remote" "${parts[0]}" "${parts[1]}"
                ;;
            
            # SHIBA_LOG_SQL_QUERY
            SQL_QUERY)
                [[ $SHIBA_LOG_SQL_QUERY = true ]] || continue
                echo -ne "    ${CYAN}sql query${CLEAR}\n"
                while IFS= read -r line; do
                    echo -ne "        $line\n"
                done <<< "$(sql_syntax_highlight "$value")"
                ;;
            
            *)
                # >&2 echo "$event not handled"
                ;;
        esac
    done < "/tmp/shibalog$REQUEST_ID"
    rm "/tmp/shibalog$REQUEST_ID"
}
export -f printlog

log() {
    echo "$*" >> "/tmp/shibalog$REQUEST_ID"
}
export -f log
