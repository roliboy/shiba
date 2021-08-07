#!/usr/bin/env bash

handle_static_file() {
    local file="$1"
    if [[ -f $file ]]; then
        local content_length="$(stat --printf='%s' "$file")"
        # TODO: something about this, it's expensive (20ms+)
        local content_type="$(file -b --mime-type "$file")"
        send_response "$STATUS_OK" "${content_length}" "${content_type}" < "$file"
        log "HANDLER_STATIC_FILE_SENT" "${file}" "${content_length}" "${content_type}"
    else
        send_response_not_found
        log "HANDLER_STATIC_FILE_NOT_FOUND" "$file"
    fi
}
export -f handle_static_file
