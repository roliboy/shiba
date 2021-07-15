#!/usr/bin/env bash

exit_handler() {
    echo -e "${YELLOW}shutting down...${NC}"
    exit 0
}

trap exit_handler SIGINT
stty -echoctl

splash

echo -e "shiba is listening"
echo -e "  --> ${YELLOW}address${NC}: ${SHIBA_ADDRESS}"
echo -e "  --> ${YELLOW}port${NC}: ${SHIBA_PORT}"
echo -e "  --> ${YELLOW}ident${NC}: shiba/${SHIBA_VERSION}"
echo -e "  --> ${YELLOW}tls${NC}: disabled"
echo -e "  --> ${YELLOW}log level${NC}: normal"
echo -e "routes:"

for entry in "${STATIC_FILES[@]}"; do
    IFS=$'\n' read -rd '' endpoint file <<< "$(split_object "$entry")"
    echo -e "  >=> ${GREEN}GET${NC} ${BLUE}${endpoint}${NC}"
    echo -e "        ${CYAN}σ${NC} $file"
done
for entry in "${STATIC_DIRECTORIES[@]}"; do
    IFS=$'\n' read -rd '' endpoint directory <<< "$(split_object "$entry")"
    echo -e "  >=> ${GREEN}GET${NC} ${BLUE}${endpoint}${NC}"
    echo -e "        ${CYAN}Σ${NC} $directory"
done
for entry in "${PROXIES[@]}"; do 
    IFS=$'\n' read -rd '' endpoint server <<< "$(split_object "$entry")"
    echo -e "  >=> ${GREEN}*${NC} ${BLUE}${endpoint}${NC}"
    echo -e "        ${CYAN}ψ${NC} $server"
done
for entry in "${COMMANDS[@]}"; do 
    IFS=$'\n' read -rd '' endpoint command <<< "$(split_object "$entry")"
    echo -e "  >=> ${GREEN}GET/POST${NC} ${BLUE}${endpoint}${NC}"
    echo -e "        ${CYAN}λ${NC} $command"
done
for entry in "${RESOURCES[@]}"; do 
    IFS=$'\n' read -rd '' endpoint resource constraints <<< "$(split_object "$entry")"
    echo -e "  >=> ${GREEN}GET/POST${NC} ${BLUE}${endpoint}${NC}"
    echo -e "        ${CYAN}δ${NC} $resource"
    echo -e "  >=> ${GREEN}GET/PUT/DELETE${NC} ${BLUE}${endpoint}/{id}${NC}"
    echo -e "        ${CYAN}δ${NC} $resource"
done
echo -e ""


while true; do
    nc -lp 1337 -e 'handle_client'
    printlog
done
