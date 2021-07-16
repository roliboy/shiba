#!/usr/bin/env bash

handle_resource_retrieve() {
    for entry in $(split_list "$model"); do
        IFS=':' read -r constraint field expected_type <<< "$entry"
        if [[ $constraint == key ]]; then
            key_field="$field"
            key_type="$expected_type"
        fi
    done

    if [[ -n $key_field ]]; then
        echo "key: $key_field" >> /tmp/pog
#         TODO: number
        if [[ $key_type == string ]]; then
            element="$(jq -c ".[] | select(.$key_field == \"$id\")" < "$resource")"
        elif [[ $key_type == number ]]; then
            element="$(jq -c ".[] | select(.$key_field == $id)" < "$resource")"
        fi
    else
        element="$(jq -c ".[] | select(.id == $id)" < "$resource")"
    fi

    send_response_ok "$element"
    log_handler_resource_retrieve "$id"
}
export -f handle_resource_retrieve
