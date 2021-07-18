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
    # TODO: replace select with values
    while read -r line; do
        if [[ $line =~ ^\'(.+)\'.*$ ]]; then
            fields+=("${BASH_REMATCH[1]}")
        fi
    done <<< "${schema//, /$'\n'}"

    printf -v data_fields "\"%s\", " "${fields[@]}"
    statement="insert into model ("
    statement="$statement${data_fields%??}"
    statement="$statement) values ("

    for field in "${fields[@]}"; do
        statement="${statement}json_extract('$blob', '\$.$field'), "
    done

    statement="${statement%??}) returning *;"

    echo "$statement"
}
export -f sql_create_statement

sql_list_statement() {
    # local resource="$1"

    echo "select * from model;"
}
export -f sql_list_statement

sql_destroy_statement() {
    local resource="$1"
    local id="$2"

    local schema
    schema="$(sqlite3 "$resource" ".schema model" | grep -oP '\(\K.*(?=\))')"

    local key_field
    local key_type
    
    while read -r line; do
        if [[ $line =~ ^\'(.+)\'[[:space:]]([^ ]+)[[:space:]]primary[[:space:]]key$ ]]; then
            key_field="${BASH_REMATCH[1]}"
            key_type="${BASH_REMATCH[2]}"
        fi
    done <<< "${schema//, /$'\n'}"

    local statement
    if [[ $key_type = text ]]; then
        statement="delete from model where \"$key_field\" = '$id' returning *;"
    else
        statement="delete from model where \"$key_field\" = $id returning *;"
    fi

    echo "$statement"
}
export -f sql_destroy_statement

sql_retrieve_statement() {
    local resource="$1"
    local id="$2"

    local schema
    schema="$(sqlite3 "$resource" ".schema model" | grep -oP '\(\K.*(?=\))')"

    local key_field
    local key_type
    
    while read -r line; do
        if [[ $line =~ ^\'(.+)\'[[:space:]]([^ ]+)[[:space:]]primary[[:space:]]key$ ]]; then
            key_field="${BASH_REMATCH[1]}"
            key_type="${BASH_REMATCH[2]}"
        fi
    done <<< "${schema//, /$'\n'}"

    local statement
    if [[ $key_type = text ]]; then
        statement="select * from model where \"$key_field\" = '$id';"
    else
        statement="select * from model where \"$key_field\" = $id;"
    fi

    echo "$statement"
}
export -f sql_retrieve_statement

sql_update_statement() {
    local resource="$1"
    local id="$2"
    local blob="$3"
    local fields=()
    local schema

    schema="$(sqlite3 "$resource" ".schema model" | grep -oP '\(\K.*(?=\))')"
    
    local key_field
    local key_type
    
    while read -r line; do
        if [[ $line =~ ^\'(.+)\'.*$ ]]; then
            fields+=("${BASH_REMATCH[1]}")
        fi
        if [[ $line =~ ^\'(.+)\'[[:space:]]([^ ]+)[[:space:]]primary[[:space:]]key$ ]]; then
            key_field="${BASH_REMATCH[1]}"
            key_type="${BASH_REMATCH[2]}"
        fi
    done <<< "${schema//, /$'\n'}"

    statement="update model set"

    for field in "${fields[@]}"; do
        statement="$statement \"$field\" = coalesce(json_extract('$blob', '\$.$field'), \"$field\"),"
    done

    if [[ $key_type = text ]]; then
        statement="${statement%?} where \"$key_field\" = '$id'"
    else
        statement="${statement%?} where \"$key_field\" = $id"
    fi
    
    statement="$statement returning *;"

    echo "$statement"
}
export -f sql_update_statement

sql_syntax_highlight() {
    local query="$1"

    local methods="json_extract|coalesce"

    local punctuation='\(|\)|,|\*|='

    local keywords='select|delete|from|insert|into|update|model|set|where|values|returning'
    local json_literal="'\{[^']*'"
    local string_literal="'[^']*'|[0-9.]+"
    local column_name='"[^"]*"'
    local regex="$keywords|$punctuation|$methods|$json_literal|$string_literal|$column_name"

    local highlighted

    local mode
    local tab=true

    # TODO: clean this
    while read -r token; do
        if [[ $token =~ $keywords ]]; then
            if [[ $token = update ]]; then
                mode=update
            fi

            if [[ $token =~ values|where|returning ]]; then
                highlighted+="\n${MAGENTA}$token${NC} "
            else
                highlighted+="${MAGENTA}$token${NC} "
            fi
        elif [[ $token =~ $methods ]]; then
            if [[ $token = json_extract ]]; then
                highlighted+="\n"
                if [[ $mode = update ]]; then
                    highlighted+="    "
                fi
                highlighted+="    ${CYAN}$token${NC}"
            else
                highlighted+="${CYAN}$token${NC}"
            fi
        elif [[ $token =~ $json_literal ]]; then
            highlighted="${highlighted% }${WHITE}$token${NC} "
        elif [[ $token =~ $string_literal ]]; then
            highlighted+="${YELLOW}$token${NC} "
        elif [[ $token =~ $column_name ]]; then
            if [[ $mode = update ]]; then
                highlighted+="\n"
                if [[ $tab = true ]]; then
                    tab=false
                else
                    highlighted+="    "
                    tab=true
                fi
                highlighted+="    ${GREEN}$token${NC} "
            else
                highlighted+="\n    ${GREEN}$token${NC} "
            fi
        elif [[ $token =~ $punctuation ]]; then
            if [[ $token = ')' ]]; then
                highlighted="${highlighted% }${WHITE}$token${NC}"
            elif [[ $token = ',' ]]; then
                highlighted="${highlighted% }${WHITE}$token${NC} "
            elif [[ $token = '=' || $token = '*' ]]; then
                highlighted+="${WHITE}$token${NC} "
            else
                highlighted+="${WHITE}$token${NC}"
            fi
        fi
    done <<< "$(grep -oP "$regex" <<< "$query")"

    echo -ne "$highlighted"
}
