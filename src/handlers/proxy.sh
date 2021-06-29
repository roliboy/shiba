#!/usr/bin/env bash

# TODO: this
parse_proxy_response() {
    read -r data
    data=${data%%$'\r'}
    
    read -r PROTOCOL CODE STATUS <<< "$data"

    # TODO: handle these
    log "PROTOCOL $PROTOCOL"
    log "CODE $CODE"
    log "STATUS $STATUS"

    while read -r line; do
        line=${line%%$'\r'}
        [ -z "$line" ] && break
        
        if [[ "$line" =~ ^[Cc]ontent-[Ll]ength:[[:space:]](.*)$ ]]; then
            contentlength="${BASH_REMATCH[1]}"
            log "Contentlength: $contentlength"
        fi
    done

    read -d'@' -r -n "$contentlength" line
    echo "$line"
}
export -f parse_proxy_response

handle_proxy() {
    method="$1"
    url="$2"

    # CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"

    # # TODO: something about this
    # read -d'@' -rn "$CONTENT_LENGTH" body
    # body=${body%%$'\r'}
    # log "BODY: $body"

    # read -ra parts <<< "$command"

    log "METHOD: $method"
    log "URL: $url"

    # echo -ne "GET ${} Host: localhost\nUser-Agent: shiba-proxy\nAccept: */*"

    # nc "$url"

    if [[ "$url" =~ ^([^:]+):([0-9]+)(\/?.*) ]]; then
        server="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
        resource="${BASH_REMATCH[3]}"

        result="$(echo -ne "$method $resource HTTP/1.1\n\n" | nc "$server" "$port")"
        result=${result%%$'\r'}
        
        content="$(parse_proxy_response <<< "$result")"
        log "CONTENT $content"

        RESPONSE_HEADERS+=("Content-Length: ${#content}")
        # TODO: set content-type to application/json if the result is valid json?
        RESPONSE_HEADERS+=("Content-Type: text/html")
        
        send "HTTP/1.0 200 OK"
        for i in "${RESPONSE_HEADERS[@]}"; do
            send "$i"
        done
        send

        # breaks when too many newlines in result
        send "$content"
    fi

    
}
export -f handle_proxy
