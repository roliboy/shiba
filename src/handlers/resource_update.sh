#!/usr/bin/env bash

handle_resource_update() {
    if [[ -z $CONTENT_LENGTH ]]; then
        send_response_length_required
        return
    fi

    body="$(head -c "$CONTENT_LENGTH" | jq -c 2>/dev/null)"
    if [[ $? != 0 ]]; then
        send_response_bad_request "could not parse request body"
        return
    fi

#     TODO: these
#     errors=()
#
#     for entry in $(split_list "$model"); do
#         IFS=':' read -r constraint field expected_type <<< "$entry"
#
#         if [[ $constraint == REQUIRED ]]; then
#             type="$(jq ".$field | type" <<< "$body" | tr -d '"')"
#             if [[ $type == null ]]; then
#                 errors+=("$field attribute is required")
#             elif [[ $expected_type == any ]]; then
#                 :
#             elif [[ $type != $expected_type ]]; then
#                 errors+=("$field attribute expected $expected_type but got $type")
#             fi
#         fi
#     done
#
#     if [[ ${#errors[@]} -gt 0 ]]; then
#         send_response_bad_request "model constraints not satisfied" "${errors[@]}"
#         return
#     fi

#     data="$(jq -c < "$resource")"
#     id="$(($(jq '[ .[] | .id ] | max' <<< "$data") + 1))"
#     element="$(jq -c ". + {id: $id}" <<< "$body")"
#     jq -c ". + [$element]" <<< "$data" > "$resource"
#
#     send_response_created "$element"

    element="$(jq -c ". + {id: $id}" <<< "$body")"
    data="$(jq -c "[ .[] | select(.id == $id) = $element ]" < "$resource")"

    echo "$data" > "$resource"

    send_response_ok "$element"
    log_handler_resource_update "$id"
}
export -f handle_resource_update
