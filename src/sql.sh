#!/usr/bin/env bash

sql_schema() {
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

    echo "create table model (${schema#?});"
}


sql_create_statement() {
    local resource="$1"
    local blob="$2"
    local fields=()
    local schema

    schema="$(sqlite3 "$resource" ".schema model" | grep -oP '\(\K.*(?=\))')"
    
    while read -r line; do
        if [[ $line =~ ^\'(.+)\'.*$ ]]; then
            fields+=("${BASH_REMATCH[1]}")
        fi
    done <<< "${schema//, /$'\n'}"

    printf -v data_fields "'%s', " "${fields[@]}"
    statement="insert into model ("
    statement="$statement${data_fields%??}"
    statement="$statement) select"

    for field in "${fields[@]}"; do
        statement="$statement json_extract('$blob', '\$.$field'),"
    done

    statement="${statement%?} returning *;"

    echo "$statement"
}
export -f sql_create_statement

sql_list_statement() {
    # local resource="$1"

    echo "select * from model;"
}
export -f sql_list_statement
