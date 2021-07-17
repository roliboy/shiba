#!/usr/bin/env bash

handle_resource_create() {
    echo "stage 0: $(date +%s:%N)" >> /tmp/pog
    local resource="$1"

    if [[ -z $CONTENT_LENGTH ]]; then
        send_response_length_required
        return
    fi

    if ! body="$(head -c "$CONTENT_LENGTH" | jq -c 2>/dev/null)"; then
        send_response_bad_request "could not parse request body"
        return
    fi

    errors=()

    # TODO: move this to sql.sh
    schema="$(sqlite3 "$resource" ".schema data" | grep -oP '\(\K.*(?=\))')"
    fields=()
    while read -r line; do
        # echo "line: $line" >> /tmp/pog
        if [[ $line =~ ^\'(.+)\'.*$ ]]; then
            # echo "${BASH_REMATCH[1]}" >> /tmp/pog
            fields+=("${BASH_REMATCH[1]}")
        fi
    done <<< "${schema//, /$'\n'}"

    printf -v data_fields "'%s', " "${fields[@]}"
    statement="insert into data ("
    statement="$statement${data_fields%??}"
    statement="$statement) select"

    for field in "${fields[@]}"; do
        statement="$statement json_extract('$body', '\$.$field'),"
    done

    statement="${statement%?} returning *;"

    # echo "statement: $statement" >> /tmp/pog

    echo "stage 1: $(date +%s:%N)" >> /tmp/pog

    object="$(sqlite3 "$resource" ".mode json" "$statement")"

    object="${object#?}"
    object="${object%?}"

    echo "$object" >> /tmp/pog
    
    # for entry in "${resource_model[@]}"; do
    #     # echo "entry: $entry" >> /tmp/pog
    #     IFS=':' read -r constraint field expected_type default <<< "$entry"

    #     # echo "default: $default" >> /tmp/pog

    #     if [[ $constraint == required ]]; then
    #         type="$(jq ".$field | type" <<< "$body" | tr -d '"')"
    #         if [[ $type == null ]]; then
    #             errors+=("$field attribute is required")
    #         elif [[ $expected_type == any ]]; then
    #             :
    #         elif [[ $type != $expected_type ]]; then
    #             errors+=("$field attribute expected $expected_type but got $type")
    #         fi
    #     elif [[ $constraint == optional ]]; then
    #         type="$(jq ".$field | type" <<< "$body" | tr -d '"')"
    #         if [[ $type == null ]]; then
    #             if [[ $expected_type == string ]]; then
    #                 body="$(jq -c ". + {$field: \"$default\"}" <<< "$body")"
    #             elif [[ $expected_type == number ]]; then
    #                 body="$(jq -c ". + {$field: $default}" <<< "$body")"
    #             fi
    #         elif [[ $expected_type == any ]]; then
    #             :
    #         elif [[ $type != $expected_type ]]; then
    #             errors+=("$field attribute expected $expected_type but got $type")
    #         fi
    #     elif [[ $constraint == key ]]; then
    #         type="$(jq ".$field | type" <<< "$body" | tr -d '"')"
    #         if [[ $type == null ]]; then
    #             errors+=("$field attribute is required")
    #         elif [[ $type != $expected_type ]]; then
    #             errors+=("$field attribute expected $expected_type but got $type")
    #         fi
    #         key_field="$field"
    #         key_value="$(jq ".$field" <<< "$body")"
    #     fi
    # done


    if [[ ${#errors[@]} -gt 0 ]]; then
        send_response_bad_request "model constraints not satisfied" "${errors[@]}"
        return
    fi

#     TODO: check for duplictes before adding
#     TODO: reduce number of jq calls because it's slow
    # echo "stage 0 $(date +%s:%N)" >> /tmp/pog

    # echo "stage 1: $(date +%s:%N)" >> /tmp/pog

    # if [[ -n $key_field ]]; then
    #     data="$(jq -c < "$resource")"
    #     id="$key_value"
    #     element="$body"
    #     jq -c ". + [$element]" <<< "$data" > "$resource"
    # else
    #     data="$(jq -c < "$resource")"
    #     id="$(($(jq '[ .[] | .id ] | max' <<< "$data") + 1))"
    #     element="$(jq -c ". + {id: $id}" <<< "$body")"
    #     jq -c ". + [$element]" <<< "$data" > "$resource"

    #     # id="$(($(jq '[ .[] | .id ] | max' < "$resource") + 1))"
    #     # element="${body%?},\"id\":$id}"
    #     # # element="$(jq -c ". + {id: $id}" <<< "$body")"

    #     # # jq -c ". + [$element]" <<< "$data" > "$resource"
    #     # sed -i "$ s/.$/,$element]/" "$resource"
    # fi


    echo "stage 2: $(date +%s:%N)" >> /tmp/pog
    send_response_created "$object"
#     TODO: log field name when using custom keys
    log_handler_resource_create "-1"
}
export -f handle_resource_create
