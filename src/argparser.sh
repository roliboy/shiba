#!/usr/bin/env bash

ADDRESS='0.0.0.0'
PORT='1337'

PROXIES=()
COMMANDS=()
RESOURCES=()
STATIC_FILES=()
STATIC_DIRECTORIES=()

join_object() {
    first="$1"
    shift
    printf "%s" "$first" "${@/#/@@@}"
}

join_array() {
    first="$1"
    shift
    printf "%s" "$first" "${@/#/;;;}"
}

split_object() {
    echo -n "${*//@@@/$'\n'}"
}
export -f split_object

split_array() {
    echo -n "${*//;;;/$'\n'}"
}
export -f split_array


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
        target="$3"
        if [[ -d $target ]]; then
            endpoint="$(sed 's:/\?$:/:g' <<< "$endpoint")"
            target="$(sed 's:/\?$:/:g' <<< "$target")"
            STATIC_DIRECTORIES+=("$(join_object "$endpoint" "$target")")
        elif [[ -f $target ]]; then
            STATIC_FILES+=("$(join_object "$endpoint" "$target")")
        else
            echo -e "${RED}ERROR${NC}: '$target' is not a valid file or directory"
            exit 1
        fi
        shift 3
        ;;
    resource)
        endpoint="$2"
        file="$3"
        RESOURCE_ENDPOINTS+=("$endpoint")
        RESOURCE_FILES+=("$file")
        shift 3
        ;;
    command)
        endpoint="$2"
        target="$3"
        COMMANDS+=("$(join_object "$endpoint" "$target")")
        shift 3
        ;;
    proxy)
        endpoint="$2"
        target="$3"
        PROXIES+=("$(join_object "$endpoint" "$target")")
        shift 3
        ;;
    *)
        echo "unknown flag/option: '$1'"
        exit 1
        ;;
esac
done

declare -x SHIBA_STATIC_FILES="$(join_array "${STATIC_FILES[@]}")"
declare -x SHIBA_STATIC_DIRECTORIES="$(join_array "${STATIC_DIRECTORIES[@]}")"
declare -x SHIBA_PROXIES="$(join_array "${PROXIES[@]}")"
declare -x SHIBA_COMMANDS="$(join_array "${COMMANDS[@]}")"

# SHIBA_RESOURCE_ENDPOINTS=$(IFS='|'; echo "${RESOURCE_ENDPOINTS[*]}")
# export SHIBA_RESOURCE_ENDPOINTS
# SHIBA_RESOURCE_FILES=$(IFS='|'; echo "${RESOURCE_FILES[*]}")
# export SHIBA_RESOURCE_FILES
# SHIBA_STATIC_ENDPOINTS=$(IFS='|'; echo "${STATIC_ENDPOINTS[*]}")
# export SHIBA_STATIC_ENDPOINTS
# SHIBA_STATIC_FILES=$(IFS='|'; echo "${STATIC_FILES[*]}")
# export SHIBA_STATIC_FILES
# SHIBA_STATIC_DIRECTORY_ENDPOINTS=$(IFS='|'; echo "${STATIC_DIRECTORY_ENDPOINTS[*]}")
# export SHIBA_STATIC_DIRECTORY_ENDPOINTS
# SHIBA_STATIC_DIRECTORIES=$(IFS='|'; echo "${STATIC_DIRECTORIES[*]}")
# export SHIBA_STATIC_DIRECTORIES
# SHIBA_FUNCTION_ENDPOINTS=$(IFS='|'; echo "${FUNCTION_ENDPOINTS[*]}")
# export SHIBA_FUNCTION_ENDPOINTS
# SHIBA_FUNCTION_TARGETS=$(IFS='|'; echo "${FUNCTION_FILES[*]}")
# export SHIBA_FUNCTION_TARGETS
# SHIBA_PROXY_ENDPOINTS=$(IFS='|'; echo "${PROXY_ENDPOINTS[*]}")
# export SHIBA_PROXY_ENDPOINTS
# SHIBA_PROXY_TARGETS=$(IFS='|'; echo "${PROXY_TARGETS[*]}")
# export SHIBA_PROXY_TARGETS
