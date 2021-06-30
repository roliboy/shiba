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
    static|s)
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
    resource|r)
        endpoint="$2"
        target="$3"
        RESOURCES+=("$(join_object "$endpoint" "$target")")
        shift 3
        ;;
    command|c)
        endpoint="$2"
        target="$3"
        COMMANDS+=("$(join_object "$endpoint" "$target")")
        shift 3
        ;;
    proxy|p)
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
declare -x SHIBA_RESOURCES="$(join_array "${RESOURCES[@]}")"
