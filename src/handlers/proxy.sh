#!/usr/bin/env bash

# TODO: this
handle_proxy_response() {
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


    # TODO: forward content-type
    RESPONSE_HEADERS+=("Content-Length: $contentlength")
    # TODO: set content-type to application/json if the result is valid json?
    RESPONSE_HEADERS+=("Content-Type: text/plain")
    
    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    head -c "$contentlength" /dev/stdin

    # echo "$content" > /tmp/shibafile
    # TODO: breaks when too many newlines in result
    # send_file /tmp/shibafile

    # read -d '@' -r -n "$contentlength" line
    # echo "$line"
    # head -c "$contentlength" /dev/stdin | base64
}
export -f handle_proxy_response

handle_proxy() {
    method="$1"
    url="$2"
    body="$(cat)"

    log "METHOD: $method"
    log "URL: $url"
    log "BODY: $body"

    # echo -ne "GET ${} Host: localhost\nUser-Agent: shiba-proxy\nAccept: */*"

    if [[ "$url" =~ ^([^:]+):([0-9]+)(\/?.*) ]]; then
        server="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
        resource="${BASH_REMATCH[3]}"

        log "SERVER: $server"
        log "PORT: $port"
        log "RESOURCE: $resource"

        # TODO: handle server error
        echo -ne "$method $resource HTTP/1.1\n\n" | nc "$server" "$port" | handle_proxy_response
        # result=${result%%$'\r'}

        # content="$(handle_proxy_response <<< "$result")"
        # log "CONTENT: $content"

        # content=${content%%$'\n'}
        # content="$(tr '\n' ' ' <<< "$content")"

        # TODO: forward content-type
        # RESPONSE_HEADERS+=("Content-Length: ${#content}")
        # # TODO: set content-type to application/json if the result is valid json?
        # RESPONSE_HEADERS+=("Content-Type: text/plain")
        
        # send "HTTP/1.0 200 OK"
        # for i in "${RESPONSE_HEADERS[@]}"; do
        #     send "$i"
        # done
        # send

        # echo "$content" > /tmp/shibafile
        # # TODO: breaks when too many newlines in result
        # send_file /tmp/shibafile
    fi
}
export -f handle_proxy
