#!/usr/bin/env bash

ADDRESS='0.0.0.0'
PORT='1337'

STATIC_ENDPOINTS=()
STATIC_FILES=()
STATIC_DIRECTORY_ENDPOINTS=()
STATIC_DIRECTORIES=()
RESOURCE_ENDPOINTS=()
RESOURCE_FILES=()
FUNCTION_ENDPOINTS=()
FUNCTION_FILES=()
PROXY_ENDPOINTS=()
PROXY_TARGETS=()

while [ "$#" -gt 0 ]; do
case "$1" in
    -h|--help)
        splash
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
    proxy)
        endpoint="$2"
        target="$3"
        PROXY_ENDPOINTS+=("$endpoint")
        PROXY_TARGETS+=("$target")
        shift 3
        ;;
    *)
        echo "unknown flag/option: '$1'"
        exit 1
        ;;
esac
done


SHIBA_RESOURCE_ENDPOINTS=$(IFS='|'; echo "${RESOURCE_ENDPOINTS[*]}")
export SHIBA_RESOURCE_ENDPOINTS
SHIBA_RESOURCE_FILES=$(IFS='|'; echo "${RESOURCE_FILES[*]}")
export SHIBA_RESOURCE_FILES
SHIBA_STATIC_ENDPOINTS=$(IFS='|'; echo "${STATIC_ENDPOINTS[*]}")
export SHIBA_STATIC_ENDPOINTS
SHIBA_STATIC_FILES=$(IFS='|'; echo "${STATIC_FILES[*]}")
export SHIBA_STATIC_FILES
SHIBA_STATIC_DIRECTORY_ENDPOINTS=$(IFS='|'; echo "${STATIC_DIRECTORY_ENDPOINTS[*]}")
export SHIBA_STATIC_DIRECTORY_ENDPOINTS
SHIBA_STATIC_DIRECTORIES=$(IFS='|'; echo "${STATIC_DIRECTORIES[*]}")
export SHIBA_STATIC_DIRECTORIES
SHIBA_FUNCTION_ENDPOINTS=$(IFS='|'; echo "${FUNCTION_ENDPOINTS[*]}")
export SHIBA_FUNCTION_ENDPOINTS
SHIBA_FUNCTION_TARGETS=$(IFS='|'; echo "${FUNCTION_FILES[*]}")
export SHIBA_FUNCTION_TARGETS
SHIBA_PROXY_ENDPOINTS=$(IFS='|'; echo "${PROXY_ENDPOINTS[*]}")
export SHIBA_PROXY_ENDPOINTS
SHIBA_PROXY_TARGETS=$(IFS='|'; echo "${PROXY_TARGETS[*]}")
export SHIBA_PROXY_TARGETS
