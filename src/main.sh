#!/usr/bin/env bash

splash

exit_handler() {
    echo -e "${YELLOW}shutting down...${NC}"
    exit 0
}

trap exit_handler SIGINT
stty -echoctl

echo -e "shiba is listening"
echo -e "  --> ${YELLOW}address${NC}: ${ADDRESS}"
echo -e "  --> ${YELLOW}port${NC}: ${PORT}"
echo -e "  --> ${YELLOW}ident${NC}: shiba/${VERSION}"
echo -e "  --> ${YELLOW}keep-alive${NC}: 5s"
echo -e "  --> ${YELLOW}tls${NC}: disabled"
echo -e "  --> ${YELLOW}log level${NC}: normal"
echo -e "routes:"
for i in "${!STATIC_ENDPOINTS[@]}"; do 
    endpoint="${STATIC_ENDPOINTS[i]}"
    file="${STATIC_FILES[i]}"
    echo -e "  >=> ${GREEN}GET${NC} ${BLUE}${endpoint}${NC}"
    echo -e "        ${CYAN}σ${NC} $file"
done
for i in "${!STATIC_DIRECTORY_ENDPOINTS[@]}"; do 
    endpoint="${STATIC_DIRECTORY_ENDPOINTS[i]}"
    file="${STATIC_DIRECTORIES[i]}"
    # TODO: decide what to do with trailing slashes
    echo -e "  >=> ${GREEN}GET${NC} ${BLUE}${endpoint}/<file..>${NC}"
    echo -e "        ${CYAN}Σ${NC} $file"
done
for i in "${!RESOURCE_ENDPOINTS[@]}"; do 
    endpoint="${RESOURCE_ENDPOINTS[i]}"
    file="${RESOURCE_FILES[i]}"
    echo -e "  >=> ${GREEN}GET/POST${NC} ${BLUE}${endpoint}${NC}"
    echo -e "        ${CYAN}δ${NC} $file"
    echo -e "  >=> ${GREEN}GET/PUT/DELETE${NC} ${BLUE}${endpoint}/<id>${NC}"
    echo -e "        ${CYAN}δ${NC} $file"
done
for i in "${!FUNCTION_ENDPOINTS[@]}"; do 
    endpoint="${FUNCTION_ENDPOINTS[i]}"
    file="${FUNCTION_FILES[i]}"
    echo -e "  >=> ${GREEN}GET/POST${NC} ${BLUE}${endpoint}${NC}"
    echo -e "        ${CYAN}λ${NC} $file"
done
echo -e ""

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
            *)
                ;;
        esac
    done < /tmp/shibalog
}

while true; do
    nc -lp 1337 -e 'handle_client'
    printlog
done
