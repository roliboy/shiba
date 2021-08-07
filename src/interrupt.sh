#!/usr/bin/env bash

sigint_handler() {
    echo -e "${YELLOW}shutting down...${CLEAR}"
    exit 0
}