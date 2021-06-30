#!/usr/bin/env bash

exit_handler() {
    echo -e "${YELLOW}shutting down...${NC}"
    exit 0
}

trap exit_handler SIGINT
stty -echoctl

splash

echo -e "shiba is listening"
echo -e "  --> ${YELLOW}address${NC}: ${ADDRESS}"
echo -e "  --> ${YELLOW}port${NC}: ${PORT}"
echo -e "  --> ${YELLOW}ident${NC}: shiba/${VERSION}"
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
# for i in "${!RESOURCE_ENDPOINTS[@]}"; do 
#     endpoint="${RESOURCE_ENDPOINTS[i]}"
#     file="${RESOURCE_FILES[i]}"
#     echo -e "  >=> ${GREEN}GET/POST${NC} ${BLUE}${endpoint}${NC}"
#     echo -e "        ${CYAN}δ${NC} $file"
#     echo -e "  >=> ${GREEN}GET/PUT/DELETE${NC} ${BLUE}${endpoint}/<id>${NC}"
#     echo -e "        ${CYAN}δ${NC} $file"
# done
# for i in "${!FUNCTION_ENDPOINTS[@]}"; do 
#     endpoint="${FUNCTION_ENDPOINTS[i]}"
#     file="${FUNCTION_FILES[i]}"
#     echo -e "  >=> ${GREEN}GET/POST${NC} ${BLUE}${endpoint}${NC}"
#     echo -e "        ${CYAN}λ${NC} $file"
# done
# for i in "${!PROXY_ENDPOINTS[@]}"; do 
#     endpoint="${PROXY_ENDPOINTS[i]}"
#     target="${PROXY_TARGETS[i]}"
#     echo -e "  >=> ${GREEN}*${NC} ${BLUE}${endpoint}${NC}"
#     echo -e "        ${CYAN}ψ${NC} $target"
# done
echo -e ""


while true; do
    nc -lp 1337 -e 'handle_client'
    printlog
done
