#!/usr/bin/env bash

handle_proxy_response() {
    read -r line
    status="${line%%$'\r'}"

    log "PROTOCOL $PROTOCOL"
    log "CODE $CODE"
    log "STATUS $STATUS"

    while read -r line; do
        line=${line%%$'\r'}
        [[ -z $line ]] && break

        if [[ "$line" =~ ^[Cc]ontent-[Ll]ength:[[:space:]](.*)$ ]]; then
            contentlength="${BASH_REMATCH[1]}"
#             log "Contentlength: $contentlength"
        fi
        if [[ "$line" =~ ^[Cc]ontent-[Tt]ype:[[:space:]](.*)$ ]]; then
            contenttype="${BASH_REMATCH[1]}"
#             log "Contenttype: $contenttype"
        fi
    done

    # TODO: check if the headers are actually present
    RESPONSE_HEADERS+=("Content-Length: $contentlength")
    RESPONSE_HEADERS+=("Content-Type: $contenttype")

    send "$status"
    send_headers

    head -c "$contentlength" /dev/stdin
    log_handler_proxy_response "$contentlength" "$contenttype"
}
export -f handle_proxy_response

handle_proxy() {
    if [[ "$url" =~ ^([^:]+):([0-9]+)(/?.*) ]]; then
        server="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
        resource="${BASH_REMATCH[3]}"

        echo "SERVER: $server" >> /tmp/pog
        echo "PORT: $port" >> /tmp/pog
        echo "RESOURCE: $resource" >> /tmp/pog

        headers="$(IFS=$'\n'; echo "${REQUEST_HEADERS[*]}")"

        if [[ -n $CONTENT_LENGTH ]]; then
            cat <(echo -ne "$REQUEST_METHOD $resource HTTP/1.1\n$headers\n\n") <(head -c "$CONTENT_LENGTH") | nc "$server" "$port" | handle_proxy_response
        else
            echo -ne "$REQUEST_METHOD $resource HTTP/1.1\n$headers\n\n" | nc "$server" "$port" | handle_proxy_response
        fi
    fi
}
export -f handle_proxy
