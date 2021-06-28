#!/bin/bash

ADDRESS='0.0.0.0'
PORT='1337'

VERSION='0.2'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'


help() {
    echo -e "${YELLOW}shiba${NC} - the good boie rest api"
    echo -e "    ${GREEN}version ${VERSION}${NC}"

    echo -e "${BLUE}usage:${NC}"
    echo -e "    $0 [flags/options] [routes]"
    echo -e "${BLUE}flags:${NC}"
    echo -e "    ${GREEN}-h${NC}, ${GREEN}--help${NC}"
    echo -e "        print this help menu"
    echo -e "${BLUE}options:${NC}"
    echo -e "    ${GREEN}-b${NC}, ${GREEN}--bind <address>${NC}"
    echo -e "        specify alternate bind address"
    echo -e "        ${MAGENTA}default${NC}: 0.0.0.0 (all interfaces)"
    echo -e "    ${GREEN}-p${NC}, ${GREEN}--port <port>${NC}"
    echo -e "        specify alternate port"
    echo -e "        ${MAGENTA}default${NC}: 8000"
    echo -e "    ${GREEN}-c${NC}, ${GREEN}--config <config-file>${NC}"
    echo -e "        load settings and routes from configuration file"
    echo -e "        ${MAGENTA}default${NC}: none"
    # TODO: rewrite these
    # TODO: prepopulate
    echo -e "${BLUE}routes:${NC}"
    echo -e "    ${CYAN}resource${NC} ${GREEN}<endpoint>${NC} ${GREEN}<file>${NC}"
    echo -e "        create a REST resource exposed at the given endpoint"
    echo -e "        storing the data in the provided file"
    echo -e "        ${YELLOW}example${NC}: ${CYAN}resource${NC} ${GREEN}/documents${NC} ${GREEN}documents.json${NC}"
    echo -e "            ${GREEN}GET${NC} ${BLUE}/documents${NC}: list all documents"
    echo -e "            ${GREEN}POST${NC} ${BLUE}/documents${NC}: create a new document and return it"
    echo -e "            ${GREEN}GET${NC} ${BLUE}/documents/<id>${NC}: retrieve the document with the given id"
    echo -e "            ${GREEN}PUT${NC} ${BLUE}/documents/<id>${NC}: update the document with the given id"
    echo -e "            ${GREEN}DELETE${NC} ${BLUE}/documents/<id>${NC}: delete document with the given id"
    echo -e "        ${MAGENTA}note${NC}: paths can include an optional trailing slash"
    # TODO: content type override
    echo -e "    ${CYAN}static${NC} ${GREEN}<endpoint>${NC} ${GREEN}<file>${NC}"
    echo -e "        statically serve the given file at the specified endpoint"
    echo -e "        ${YELLOW}example${NC}: ${CYAN}static${NC} ${GREEN}/${NC} ${GREEN}index.html${NC}"
    echo -e "            will statically serve the 'index.html' file on /"
    echo -e "        ${MAGENTA}note${NC}: automatically sets Content-Type header based on file type"
    # 
    echo -e "    ${CYAN}directory${NC} ${GREEN}<endpoint>${NC} ${GREEN}<directory>${NC}"
    echo -e "        statically serve all files in the given directory at specified endpoint"
    echo -e "        ${YELLOW}example${NC}: ${CYAN}directory${NC} ${GREEN}/static/${NC} ${GREEN}./media${NC}"
    echo -e "            will statically all files in the 'media' directory on /static/"
    echo -e "            suppose the 'media' directory contained a file 'logo.png'"
    echo -e "            and a subdirectory 'profiles' containing a file named 'user.png'"
    echo -e "            'logo.png' can be accessed at /static/logo.png"
    echo -e "            'user.png' can be accessed at /static/profiles/user.png"
    echo -e "        ${MAGENTA}note${NC}: Content-Type header is automatically set based on file type"
    # 
    echo -e "    ${CYAN}function${NC} ${RED}[WIP]${NC}"
    echo -e "        run executable/script and return output"
    echo -e "    ${CYAN}proxy${NC} ${RED}[WIP]${NC}"
    echo -e "        forward all requests from this endpoint to another server/endpoint"
}

STATIC_ENDPOINTS=()
STATIC_FILES=()
STATIC_DIRECTORY_ENDPOINTS=()
STATIC_DIRECTORIES=()
RESOURCE_ENDPOINTS=()
RESOURCE_FILES=()
FUNCTION_ENDPOINTS=()
FUNCTION_FILES=()

while [ "$#" -gt 0 ]; do
case "$1" in
    -h|--help)
        ./splash
        help
        exit 0
        shift
        ;;
    -b|--bind)
        ADDRESS="$2"
        shift 2
        ;;
    -p|--port)
        PORT="$2"
        shift 2
        ;;
    static)
        endpoint="$2"
        file="$3"
        STATIC_ENDPOINTS+=("$endpoint")
        STATIC_FILES+=("$file")
        shift 3
        ;;
    # TODO: replace this
    directory)
        endpoint="$2"
        directory="$3"
        STATIC_DIRECTORY_ENDPOINTS+=("$endpoint")
        STATIC_DIRECTORIES+=("$directory")
        shift 3
        ;;
    resource)
        endpoint="$2"
        file="$3"
        RESOURCE_ENDPOINTS+=("$endpoint")
        RESOURCE_FILES+=("$file")
        shift 3
        ;;
    function)
        endpoint="$2"
        file="$3"
        FUNCTION_ENDPOINTS+=("$endpoint")
        FUNCTION_FILES+=("$file")
        shift 3
        ;;
    *)
        echo "unknown flag/option: '$1'"
        exit 1
        ;;
esac
done



./splash


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
    echo -e "  >=> ${GREEN}GET${NC} ${BLUE}${endpoint}${NC}"
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

SHIBA_RESOURCE_ENDPOINTS=$(IFS='|'; echo "${RESOURCE_ENDPOINTS[*]}")
export SHIBA_RESOURCE_ENDPOINTS
SHIBA_RESOURCE_FILES=$(IFS='|'; echo "${RESOURCE_FILES[*]}")
export SHIBA_RESOURCE_FILES
SHIBA_STATIC_ENDPOINTS=$(IFS='|'; echo "${STATIC_ENDPOINTS[*]}")
export SHIBA_STATIC_ENDPOINTS
SHIBA_STATIC_FILES=$(IFS='|'; echo "${STATIC_FILES[*]}")
export SHIBA_STATIC_FILES


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
    nc -lp 1337 -e ./shiba.sh
    printlog
done
