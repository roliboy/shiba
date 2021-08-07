#!/usr/bin/env bash

set -o nounset
# set -o xtrace
set -o pipefail

trap sigint_handler SIGINT
stty -echoctl

system_check

splash

logs=""
[[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] && logs+="endpoint match, "
[[ $SHIBA_LOG_RESPONSE_CODE = true ]] && logs+="response code, "
[[ $SHIBA_LOG_HANDLER_STATUS = true ]] && logs+="handler status, "
[[ $SHIBA_LOG_SQL_QUERY = true ]] && logs+="sql query, "

printf "shiba is listening\n"
printf "  --> ${YELLOW}address${CLEAR}: ${SHIBA_ADDRESS}\n"
printf "  --> ${YELLOW}port${CLEAR}: ${SHIBA_PORT}\n"
printf "  --> ${YELLOW}ident${CLEAR}: shiba/${SHIBA_VERSION}\n"
printf "  --> ${YELLOW}tls${CLEAR}: disabled\n"
printf "  --> ${YELLOW}log${CLEAR}: ${logs%, }\n"

printf "routes:\n"
while read -r entry; do
    [[ -z $entry ]] && continue
    IFS='|' read -r endpoint file <<< "${entry}"
    printf "  >=> ${GREEN}GET${CLEAR} ${BLUE}%s${CLEAR}\n" "${endpoint}"
    printf "    ${CYAN}σ${CLEAR} $file\n"
done <<< "${SHIBA_STATIC_FILES}"
while read -r entry; do
    [[ -z $entry ]] && continue
    IFS='|' read -r endpoint directory <<< "${entry}"
    printf "  >=> ${GREEN}GET${CLEAR} ${BLUE}${endpoint}${CLEAR}\n"
    printf "    ${CYAN}Σ${CLEAR} $directory\n"
done <<< "${SHIBA_STATIC_DIRECTORIES}"
while read -r entry; do
    [[ -z $entry ]] && continue
    IFS='|' read -r endpoint server <<< "${entry}"
    printf "  >=> ${GREEN}*${CLEAR} ${BLUE}${endpoint}${CLEAR}\n"
    printf "    ${CYAN}ψ${CLEAR} $server\n"
done <<< "${SHIBA_PROXIES}"
while read -r entry; do
    [[ -z $entry ]] && continue
    IFS='|' read -r endpoint command <<< "${entry}"
    printf "  >=> ${GREEN}*${CLEAR} ${BLUE}${endpoint}${CLEAR}\n"
    printf "    ${CYAN}λ${CLEAR} $command\n"
done <<< "${SHIBA_COMMANDS}"
# TODO: replace {id} with key column name
while read -r entry; do
    [[ -z $entry ]] && continue
    IFS='|' read -r endpoint resource <<< "${entry}"
    printf "  >=> ${GREEN}GET/POST${CLEAR} ${BLUE}${endpoint}${CLEAR}\n"
    printf "    ${CYAN}δ${CLEAR} $resource\n"
    printf "  >=> ${GREEN}GET/PUT/DELETE${CLEAR} ${BLUE}${endpoint}/{id}${CLEAR}\n"
    printf "    ${CYAN}δ${CLEAR} $resource\n"
done <<< "${SHIBA_RESOURCES}"
printf "\n"

# TODO: add timeout
socat tcp-listen:"${SHIBA_PORT}",fork,reuseaddr system:"handle_client"
# socat -lf /dev/null tcp-listen:1337,fork,reuseaddr system:'handle_client'
