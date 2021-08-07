#!/usr/bin/env bash

handle_command() {
    local command="$1"
    local args=("${@:2}")

    read -ra parts <<< "$command"
    command="${parts[0]}"
    arguments=("${parts[@]:1}" "${args[@]}")
    
    SHIBA_REQUEST_METHOD="$REQUEST_METHOD"
    export SHIBA_REQUEST_METHOD

#     TODO: binary support?
    outfile="/tmp/shibatmp${BASHPID}"
    if [[ ${#arguments[@]} -eq 0 ]]; then
        if [[ -n ${CONTENT_LENGTH+x} ]]; then
            head -c "$CONTENT_LENGTH" | "$command" > "$outfile"
        else
            "$command" <<< "" > "$outfile"
        fi
    else
        if [[ -n ${CONTENT_LENGTH+x} ]]; then
            head -c "$CONTENT_LENGTH" | "$command" "${arguments[@]}" > "$outfile"
        else
            "$command" "${arguments[@]}" <<< "" > "$outfile"
        fi
    fi

    exit_code="$?"

    # TODO: get content type from command
    # TODO: get status from command
    local content_length="$(stat --printf='%s' "$outfile")"
    local content_type="$(file -b --mime-type "$outfile")"

    if [[ $exit_code -eq 0 ]]; then
        send_response "$STATUS_OK" "${content_length}" "${content_type}" < "${outfile}"
        # TODO: add info about stdin
        log "HANDLER_COMMAND_SUCCESS" "${content_length}" "${content_type}" "${command} ${arguments[@]}"
    else
        send_response_internal_server_error
        # TODO: add info about stdin
        log "HANDLER_COMMAND_ERROR" "${exit_code}" "${command} ${arguments[@]}"
    fi

    rm "$outfile"
}
export -f handle_command
