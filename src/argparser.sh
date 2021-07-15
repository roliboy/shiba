#!/usr/bin/env bash

SHIBA_ADDRESS='0.0.0.0'
SHIBA_PORT='1337'

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

join_list() {
    first="$1"
    shift
    printf "%s" "$first" "${@/#/%%%}"
}

split_object() {
    echo -n "${*//@@@/$'\n'}"
}

split_array() {
    echo -n "${*//;;;/$'\n'}"
}

split_list() {
    echo -n "${*//%%%/$'\n'}"
}


while [ "$#" -gt 0 ]; do
case "$1" in
    -h|--help)
        splash
        help
        exit 0
        shift
        ;;
    -b|--bind)
        SHIBA_ADDRESS="$2"
        shift 2
        ;;
    -p|--port)
        SHIBA_PORT="$2"
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
    # TODO:make this look not horrible
    resource|r)
        endpoint="$2"
        target="$3"
        model=()

        shift 3
        if [[ $1 == '[' ]]; then
            shift
            while [[ $# -gt 0 ]] && [[ $1 != ']' ]]; do
                if [[ $1 =~ ^([!%]?)([^:]+):?(.*)$ ]]; then
                    modifier="${BASH_REMATCH[1]:-REQUIRED}"
                    field="${BASH_REMATCH[2]}"
                    type="${BASH_REMATCH[3]:-any}"
#                     [[ $modifier == '!' ]] && modifier='REQUIRED'
                    model+=("$modifier:$field:$type")
                fi
                shift
            done
            [[ $1 == ']' ]] && shift
        fi

        RESOURCES+=("$(join_object "$endpoint" "$target" "$(join_list "${model[@]}")")")
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
        PROXIES+=("$(join_object "${endpoint%/}" "${target%/}")")
        shift 3
        ;;
    *)
        echo "unknown flag/option: '$1'"
        exit 1
        ;;
esac
done

SHIBA_STATIC_FILES="$(join_array "${STATIC_FILES[@]}")"
SHIBA_STATIC_DIRECTORIES="$(join_array "${STATIC_DIRECTORIES[@]}")"
SHIBA_PROXIES="$(join_array "${PROXIES[@]}")"
SHIBA_COMMANDS="$(join_array "${COMMANDS[@]}")"
SHIBA_RESOURCES="$(join_array "${RESOURCES[@]}")"

export SHIBA_ADDRESS
export SHIBA_PORT

export -f split_object
export -f split_array
export -f split_list

export SHIBA_STATIC_FILES
export SHIBA_STATIC_DIRECTORIES
export SHIBA_PROXIES
export SHIBA_COMMANDS
export SHIBA_RESOURCES
