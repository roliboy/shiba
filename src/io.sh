#!/urs/bin/env bash

recv() {
    local data
    read -r data
    data=${data%%$'\r'}
    # log_received_data "$data"
    echo -n "$data"
}
export -f recv

recv2() {
    local -n lineasd="$1"
    read -r data
    lineasd=${data%%$'\r'}
    # log_received_data "$data"
}
export -f recv2

send() {
#     log_sent_data "$*"
    printf '%s\r\n' "$*"
}
export -f send

send_file() {
#     log_sent_data "file $1"
    cat "$1"
}
export -f send_file
