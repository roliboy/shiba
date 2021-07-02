#!/usr/bin/env bash

handle_proxy_response() {
    read -r data
    read -r PROTOCOL CODE STATUS <<< "${data%%$'\r'}"

    # TODO: handle these
    log "PROTOCOL $PROTOCOL"
    log "CODE $CODE"
    log "STATUS $STATUS"

    while read -r line; do
        line=${line%%$'\r'}
        [[ -z $line ]] && break
        
        if [[ "$line" =~ ^[Cc]ontent-[Ll]ength:[[:space:]](.*)$ ]]; then
            contentlength="${BASH_REMATCH[1]}"
            log "Contentlength: $contentlength"
        fi
        if [[ "$line" =~ ^[Cc]ontent-[Tt]ype:[[:space:]](.*)$ ]]; then
            contenttype="${BASH_REMATCH[1]}"
            log "Contenttype: $contenttype"
        fi
    done

    # TODO: check if the headers are actually present
    RESPONSE_HEADERS+=("Content-Length: $contentlength")
    RESPONSE_HEADERS+=("Content-Type: $contenttype")
    
    # TODO: forward status code
    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    head -c "$contentlength" /dev/stdin
    log_handler_proxy_response "$contentlength" "$contenttype"
}
export -f handle_proxy_response

handle_proxy() {
    method="$1"
    url="$2"

    log "METHOD: $method"
    log "URL: $url"
    
    # echo -ne "GET ${} Host: localhost\nUser-Agent: shiba-proxy\nAccept: */*"

    if [[ "$url" =~ ^([^:]+):([0-9]+)(\/?.*) ]]; then
        server="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
        resource="${BASH_REMATCH[3]}"

        log "SERVER: $server"
        log "PORT: $port"
        log "RESOURCE: $resource"

        # TODO: concatenate data `cat <(echo method resource protocol) <(head -c contentlength /dev/stdin)`
        echo -ne "$method $resource HTTP/1.1\n\n" | nc "$server" "$port" | handle_proxy_response
    fi
}
export -f handle_proxy
