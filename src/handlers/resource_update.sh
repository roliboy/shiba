#!/usr/bin/env bash

handle_resource_update() {
    resource_file="$1"
    resource_id="$2"

    CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"

    read -rn "$CONTENT_LENGTH" body
    body=${body%%$'\r'}
    log "BODY: $body"

    data="$(cat "$resource_file")"
    element="$(jq -c ". + {id: $resource_id}" <<< "$body")"
    data="$(jq -c "[ .[] | select(.id == $resource_id) = $element ]" <<< "$data")"

    echo "$data" > "$resource_file"

    RESPONSE_HEADERS+=("Content-Length: ${#element}")
    RESPONSE_HEADERS+=("Content-Type: application/json")
    
    send "HTTP/1.0 200 OK"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    send "$element"
}
export -f handle_resource_update
