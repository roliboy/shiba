#!/usr/bin/env bash

set -o nounset
# set -o xtrace
set -o pipefail

trap sigint_handler SIGINT
stty -echoctl

system_check

splash

logs=""
[[ $SHIBA_LOG_ENDPOINT_MATCH = true ]] && logs+="endpoint matches, "
[[ $SHIBA_LOG_SQL_QUERY = true ]] && logs+="sql queries, "

printf "shiba is listening\n"
printf "  --> ${YELLOW}address${CLEAR}: ${SHIBA_ADDRESS}\n"
printf "  --> ${YELLOW}port${CLEAR}: ${SHIBA_PORT}\n"
printf "  --> ${YELLOW}ident${CLEAR}: shiba/${SHIBA_VERSION}\n"
printf "  --> ${YELLOW}tls${CLEAR}: disabled\n"
printf "  --> ${YELLOW}log${CLEAR}: ${logs%, }\n"

printf "routes:\n"
while read -r entry; do
    IFS='|' read -r endpoint file <<< "${entry}"
    printf "  >=> ${GREEN}GET${CLEAR} ${BLUE}%s${CLEAR}\n" "${endpoint}"
    printf "    ${CYAN}σ${CLEAR} $file\n"
done <<< "${SHIBA_STATIC_FILES}"
for entry in "${STATIC_DIRECTORIES[@]}"; do
    IFS=$'\n' read -rd '' endpoint directory <<< "$(split_object "$entry")"
    printf "  >=> ${GREEN}GET${CLEAR} ${BLUE}${endpoint}${CLEAR}\n"
    printf "    ${CYAN}Σ${CLEAR} $directory\n"
done
for entry in "${PROXIES[@]}"; do 
    IFS=$'\n' read -rd '' endpoint server <<< "$(split_object "$entry")"
    printf "  >=> ${GREEN}*${CLEAR} ${BLUE}${endpoint}${CLEAR}\n"
    printf "    ${CYAN}ψ${CLEAR} $server\n"
done
for entry in "${COMMANDS[@]}"; do 
    IFS=$'\n' read -rd '' endpoint command <<< "$(split_object "$entry")"
    printf "  >=> ${GREEN}*${CLEAR} ${BLUE}${endpoint}${CLEAR}\n"
    printf "    ${CYAN}λ${CLEAR} $command\n"
done
# TODO: replace {id} with key column name
for entry in "${RESOURCES[@]}"; do 
    IFS=$'\n' read -rd '' endpoint resource <<< "$(split_object "$entry")"
    printf "  >=> ${GREEN}GET/POST${CLEAR} ${BLUE}${endpoint}${CLEAR}\n"
    printf "    ${CYAN}δ${CLEAR} $resource\n"
    printf "  >=> ${GREEN}GET/PUT/DELETE${CLEAR} ${BLUE}${endpoint}/{id}${CLEAR}\n"
    printf "    ${CYAN}δ${CLEAR} $resource\n"
done
printf "\n"

# TODO: add timeout
socat tcp-listen:1337,fork,reuseaddr system:"handle_client"
# socat -lf /dev/null tcp-listen:1337,fork,reuseaddr system:'handle_client'
