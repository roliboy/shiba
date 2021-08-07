#!/usr/bin/env bash

get_package_manager() {
    [[ -f /etc/debian_version ]] && echo apt-get && return
    [[ -f /etc/arch-release ]] && echo pacman && return
}

check_dependencies() {
    # TODO: use package manager to suggest command
    package_manager="$(get_package_manager)"

    if ! command -v socat > /dev/null; then
        echo -e "${RED}ERROR:${CLEAR} socat not installed"
        echo -e "  this is a core component required by shiba"
        echo -e "  socat's purpose is to listen for requests and send responses"
        echo -e "  you can install it by running the following command:"
        echo -e "  ┌────────────────────┐"
        echo -e "  │ \$ ${CYAN}pacman${CLEAR} ${GREEN}-Sy${CLEAR} socat │"
        echo -e "  └────────────────────┘"
        echo -e ""
    fi
    
    if ! command -v sqlite3 > /dev/null; then
        echo -e "${YELLOW}WARNING:${CLEAR} sqlite3 not installed"
        echo -e "  this is an optional component required by the 'resource' module"
        echo -e "  it's used to execute sql queries on the resource database"
        echo -e "  ignore this warning if you're not planning to use the resource feature"
        echo -e "  otherwise install sqlite3 by running the following command:"
        echo -e "  ┌──────────────────────┐"
        echo -e "  │ \$ ${CYAN}pacman${CLEAR} ${GREEN}-Sy${CLEAR} sqlite3 │"
        echo -e "  └──────────────────────┘"
    fi

    # TODO: exit if there were errors
}

system_check() {
    check_dependencies
}
