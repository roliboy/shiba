#!/usr/bin/env bash

generate_schema() {
    local model=("$@")

    local schema
    local key_field
    local key_type

    for entry in "${model[@]}"; do
        IFS=':' read -r field modifier type default <<< "$entry"
        if [[ $modifier == key ]]; then
            key_field="$field"
            key_type="$type"
        elif [[ $modifier == required ]]; then
            schema="$schema '$field' $type not null,"
        elif [[ $modifier == optional ]]; then
            if [[ $type == text ]]; then
                schema="$schema '$field' $type not null on conflict replace default '$default',"
            else
                schema="$schema '$field' $type not null on conflict replace default $default,"
            fi
        fi
    done

    if [[ -n $key_field ]]; then
        schema="$schema '$key_field' $key_type primary key"
    else
        schema="$schema 'id' integer primary key"
    fi

    echo "create table data (${schema#?});"
}
