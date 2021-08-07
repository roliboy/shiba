#!/usr/bin/env bash

SHIBA_VERSION='0.3'

export SHIBA_VERSION


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
CLEAR='\033[0m'

export RED
export GREEN
export YELLOW
export BLUE
export MAGENTA
export CYAN
export WHITE
export CLEAR


STATUS_OK="200 OK"
STATUS_CREATED="201 Created"
STATUS_NO_CONTENT="204 No Content"

STATUS_BAD_REQUEST="400 Bad Request"
STATUS_NOT_FOUND="404 Not Found"
STATUS_METHOD_NOT_ALLOWED="405 Method Not Allowed"
STATUS_LENGTH_REQUIRED="411 Length Required"
STATUS_INTERNAL_SERVER_ERROR="500 Internal Server Error"

export STATUS_OK
export STATUS_CREATED
export STATUS_NO_CONTENT
export STATUS_BAD_REQUEST
export STATUS_NOT_FOUND
export STATUS_METHOD_NOT_ALLOWED
export STATUS_LENGTH_REQUIRED
export STATUS_INTERNAL_SERVER_ERROR
