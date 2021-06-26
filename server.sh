#!/bin/bash

./splash

# BLACK='\033[0;30m'
# RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
# MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
# WHITE='\033[0;37m'
NC='\033[0m'

exit_handler() {
    echo -e "${YELLOW}shutting down...${NC}"
    exit 0
}

trap exit_handler SIGINT
stty -echoctl


echo -e "shiba is listening"
echo -e "  --> ${YELLOW}address${NC}: 127.0.0.1"
echo -e "  --> ${YELLOW}port${NC}: 8000"
echo -e "  --> ${YELLOW}ident${NC}: shiba/0.2"
echo -e "  --> ${YELLOW}keep-alive${NC}: 5s"
echo -e "  --> ${YELLOW}tls${NC}: disabled"
echo -e "  --> ${YELLOW}base directory${NC}: ."
echo -e "  --> ${YELLOW}log level${NC}: normal"
echo -e "routes:"
echo -e "  >=> ${GREEN}GET${NC} ${BLUE}/${NC}"
echo -e "        ${CYAN}λ${NC} index"
echo -e "  >=> ${GREEN}PUT${NC} ${BLUE}/resource/<id>${NC}"
echo -e "        ${CYAN}λ${NC} something"

while true
do
    nc -lp 1337 -e ./shiba.sh
   #  nc -lp 1337 -e '
   #      echo -ne "REEEE" > request.log
   #  '
   #  cat request.log
done
