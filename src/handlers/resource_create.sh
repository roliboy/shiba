#!/usr/bin/env bash

handle_resource_create() {
    if [[ -z $CONTENT_LENGTH ]]; then
        send_response_length_required
        return
    fi

    body="$(head -c "$CONTENT_LENGTH" | jq -c 2>/dev/null)"
    if [[ $? != 0 ]]; then
        send_response_bad_request "could not parse request body"
        return
    fi

    errors=()

#     TODO: make this look not horrible
#     TODO: save only fields declared in the model
    for entry in $(split_list "$model"); do
        IFS=':' read -r constraint field expected_type <<< "$entry"

        if [[ $constraint == required ]]; then
            type="$(jq ".$field | type" <<< "$body" | tr -d '"')"
            if [[ $type == null ]]; then
                errors+=("$field attribute is required")
            elif [[ $expected_type == any ]]; then
                :
            elif [[ $type != $expected_type ]]; then
                errors+=("$field attribute expected $expected_type but got $type")
            fi
        elif [[ $constraint == optional ]]; then
            type="$(jq ".$field | type" <<< "$body" | tr -d '"')"
            if [[ $type == null ]]; then
                :
            elif [[ $expected_type == any ]]; then
                :
            elif [[ $type != $expected_type ]]; then
                errors+=("$field attribute expected $expected_type but got $type")
            fi
        elif [[ $constraint == key ]]; then
            type="$(jq ".$field | type" <<< "$body" | tr -d '"')"
            if [[ $type == null ]]; then
                errors+=("$field attribute is required")
            elif [[ $type != $expected_type ]]; then
                errors+=("$field attribute expected $expected_type but got $type")
            fi
            key_field="$field"
            key_value="$(jq ".$field" <<< "$body")"
        fi
    done

    if [[ ${#errors[@]} -gt 0 ]]; then
        send_response_bad_request "model constraints not satisfied" "${errors[@]}"
        return
    fi

#     TODO: check for duplictes before adding
    if [[ -n $key_field ]]; then
        data="$(jq -c < "$resource")"
        id="$key_value"
        element="$body"
        jq -c ". + [$element]" <<< "$data" > "$resource"
    else
        data="$(jq -c < "$resource")"
        id="$(($(jq '[ .[] | .id ] | max' <<< "$data") + 1))"
        element="$(jq -c ". + {id: $id}" <<< "$body")"
        jq -c ". + [$element]" <<< "$data" > "$resource"
    fi

    send_response_created "$element"
#     TODO: log field name when using custom keys
    log_handler_resource_create "$id"
}
export -f handle_resource_create
