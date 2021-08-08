#!/usr/bin/env bash

# TODO: timeout support
handle_proxy_response() {
    read -r line
    status="${line%%$'\r'}"

    read -ra proxy_response_status <<< "${line}"
    http_version="${proxy_response_status[0]}"
    response_code="${proxy_response_status[1]}"
    response_status="${proxy_response_status[*]:2}"

    # TODO: handle malformed response from proxy server
    # if [[ -z $REQUEST_METHOD ]]; then
    #     send_response_bad_request "no request method in http request header"
    #     log "REQUEST_NO_METHOD"
    #     quit
    # fi
    # if [[ -z $REQUEST_URI ]]; then
    #     send_response_bad_request "no uri in http request header"
    #     log "REQUEST_NO_URI"
    #     quit
    # fi
    # if [[ -z $REQUEST_HTTP_VERSION ]]; then
    #     send_response_bad_request "no http version in http request header"
    #     log "REQUEST_NO_HTTP_VERSION"
    #     quit
    # fi

    while read -r line; do
        line=${line%%$'\r'}
        [[ -z $line ]] && break

        if [[ ${line} =~ ^[Cc]ontent-[Ll]ength:[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]]; then
            contentlength="${BASH_REMATCH[1]}"
        fi
        if [[ ${line} =~ ^[Cc]ontent-[Tt]ype:[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]]; then
            contenttype="${BASH_REMATCH[1]}"
        fi
    done

    if [[ -z ${contentlength+x} ]]; then
        :
    fi
    if [[ -z ${contenttype+x} ]]; then
        :
    fi

    # TODO: copy over response headers?
    # TODO: remap response codes
    send_response "$response_code $response_status" "$contentlength" "$contenttype"
    log "HANDLER_PROXY_SUCCESS" "$contentlength" "$contenttype"
}
export -f handle_proxy_response

handle_proxy() {
    local url="${1}"
    
    # TODO: include protocol
    if [[ ${url} =~ ^([^:]+):([0-9]+)(/?.*) ]]; then
        server="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
        resource="${BASH_REMATCH[3]}"

        headers="$(IFS=$'\n'; echo "${REQUEST_HEADERS[*]}")"

        if [[ -n ${CONTENT_LENGTH+x} ]]; then
            cat <(printf "%s %s HTTP/1.1\n%s\n\n" "$REQUEST_METHOD" "$resource" "$headers") <(head -c "$CONTENT_LENGTH") | socat - "TCP:$server:$port" | handle_proxy_response
        else
            printf "%s %s HTTP/1.1\n%s\n\n" "$REQUEST_METHOD" "$resource" "$headers" | socat - "TCP:$server:$port" | handle_proxy_response
        fi
    fi
}
export -f handle_proxy
