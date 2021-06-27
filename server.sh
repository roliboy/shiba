#!/bin/bash


ADDRESS='0.0.0.0'
PORT='1337'

VERSION='0.2'

# BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
# WHITE='\033[0;37m'
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
    echo -e "    ${CYAN}resource${NC} ${GREEN}<endpoint>${NC} ${GREEN}<file?>${NC}"
    echo -e "        create a REST resource exposed at the given endpoint"
    echo -e "        optionally can use existing data in the provided file"
    echo -e "        ${GREEN}GET${NC} ${BLUE}/path${NC}: list all entities"
    echo -e "        ${GREEN}POST${NC} ${BLUE}/path${NC}: create and return a new entity"
    echo -e "        ${GREEN}GET${NC} ${BLUE}/path/<id>${NC}: retrieve the entity with the given id"
    echo -e "        ${GREEN}PUT${NC} ${BLUE}/path/<id>${NC}: update the entity with the given id"
    echo -e "        ${GREEN}DELETE${NC} ${BLUE}/path/<id>${NC}: delete entity with the given id"
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
    resource)
        endpoint="$2"
        shift 2
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
echo -e "  --> ${YELLOW}base directory${NC}: ."
echo -e "  --> ${YELLOW}log level${NC}: normal"
echo -e "routes:"
echo -e "  >=> ${GREEN}GET${NC} ${BLUE}/${NC}"
echo -e "        ${CYAN}λ${NC} index"
echo -e "  >=> ${GREEN}PUT${NC} ${BLUE}/resource/<id>${NC}"
echo -e "        ${CYAN}λ${NC} something"

# Σ - static directory
# σ - static file
# λ - function
# δ - rest resource

while true
do
    nc -lp 1337 -e ./shiba.sh
   #  nc -lp 1337 -e '
   #      echo -ne "REEEE" > request.log
   #  '
   #  cat request.log
done
