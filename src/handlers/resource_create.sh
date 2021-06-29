#!/usr/bin/env bash

handle_resource_create() {
    resource_file="$1"
 
    CONTENT_LENGTH="${REQUEST_HEADERS[Content-Length]}"

    read -rn "$CONTENT_LENGTH" body
    body=${body%%$'\r'}
    recv "BODY: $body"

    data="$(cat "$resource_file")"
    id="$(($(jq '.[-1].id' <<< "$data") + 1))"
    element="$(jq -c ". + {id: $id}" <<< "$body")"
    data="$(jq -c ". + [$element]" <<< "$data")"

    echo "$data" > "$resource_file"
    
    RESPONSE_HEADERS+=("Content-Length: ${#element}")
    RESPONSE_HEADERS+=("Content-Type: application/json")
    send "HTTP/1.0 201 CREATED"
    for i in "${RESPONSE_HEADERS[@]}"; do
        send "$i"
    done
    send

    send "$element"
}
export -f handle_resource_create
