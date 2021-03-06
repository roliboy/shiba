#!/usr/bin/env bash

help() {
    echo -e "${YELLOW}shiba${CLEAR} - the good boie rest api"
    echo -e "    ${GREEN}version ${SHIBA_VERSION}${CLEAR}"

    echo -e "${BLUE}usage:${CLEAR}"
    echo -e "    $0 [flags/options] [routes]"
    echo -e "${BLUE}flags:${CLEAR}"
    echo -e "    ${GREEN}-h${CLEAR}, ${GREEN}--help${CLEAR}"
    echo -e "        print this help menu"
    echo -e "    ${GREEN}-q${CLEAR}, ${GREEN}--log-sql-query${CLEAR}"
    echo -e "        log executed sql queries when performing CRUD operations on resources"
    echo -e "    ${GREEN}-e${CLEAR}, ${GREEN}--log-endpoint-match${CLEAR}"
    echo -e "        log the endpoint that matched the request uri and the regex used"
    echo -e "${BLUE}options:${CLEAR}"
    echo -e "    ${GREEN}-b${CLEAR}, ${GREEN}--bind <address>${CLEAR}"
    echo -e "        specify bind address"
    echo -e "        ${MAGENTA}default${CLEAR}: 0.0.0.0 (all interfaces)"
    echo -e "    ${GREEN}-p${CLEAR}, ${GREEN}--port <port>${CLEAR}"
    echo -e "        specify port"
    echo -e "        ${MAGENTA}default${CLEAR}: 8000"
    # echo -e "    ${GREEN}-c${CLEAR}, ${GREEN}--config <config-file>${CLEAR}"
    # echo -e "        load settings and routes from configuration file"
    # echo -e "        ${MAGENTA}default${CLEAR}: none"
    echo -e "${BLUE}routes:${CLEAR}"
    # TODO: json/sql representation based on file extension
    echo -e "    ${CYAN}resource${CLEAR} ${GREEN}<endpoint>${CLEAR} ${GREEN}<file>${CLEAR}"
    echo -e "        create a REST resource exposed at the given endpoint"
    echo -e "        storing the data in the provided file"
    echo -e "        ${YELLOW}example${CLEAR}: ${CYAN}resource${CLEAR} ${GREEN}/documents${CLEAR} ${GREEN}documents.json${CLEAR}"
    echo -e "            ${GREEN}GET${CLEAR} ${BLUE}/documents${CLEAR}: list all documents"
    echo -e "            ${GREEN}POST${CLEAR} ${BLUE}/documents${CLEAR}: create a new document and return it"
    echo -e "            ${GREEN}GET${CLEAR} ${BLUE}/documents/<id>${CLEAR}: retrieve the document with the given id"
    echo -e "            ${GREEN}PUT${CLEAR} ${BLUE}/documents/<id>${CLEAR}: update the document with the given id"
    echo -e "            ${GREEN}DELETE${CLEAR} ${BLUE}/documents/<id>${CLEAR}: delete document with the given id"
    echo -e "        ${MAGENTA}note${CLEAR}: paths can include an optional trailing slash"
    # TODO: content type override
    echo -e "    ${CYAN}static${CLEAR} ${GREEN}<endpoint>${CLEAR} ${GREEN}<file|directory>${CLEAR}"
    echo -e "        statically serve the given file or directory at the specified endpoint"
    echo -e "        ${YELLOW}example${CLEAR}: ${CYAN}static${CLEAR} ${GREEN}/${CLEAR} ${GREEN}index.html${CLEAR}"
    echo -e "            will statically serve the 'index.html' file on /"
    echo -e "        ${YELLOW}example${CLEAR}: ${CYAN}static${CLEAR} ${GREEN}/static/${CLEAR} ${GREEN}./media${CLEAR}"
    echo -e "            will statically serve all files from the 'media' directory on /static/"
    echo -e "            suppose the 'media' directory contained a file 'logo.png'"
    echo -e "            and a subdirectory 'profiles' containing a file named 'user.png'"
    echo -e "            'logo.png' can be accessed at /static/logo.png"
    echo -e "            'user.png' can be accessed at /static/profiles/user.png"
    echo -e "        ${MAGENTA}note${CLEAR}: automatically sets Content-Type header based on file type"
    echo -e "    ${CYAN}command${CLEAR} ${GREEN}<endpoint>${CLEAR} ${GREEN}<file|command>${CLEAR}"
    echo -e "        execute file or command and return the generated output"
    echo -e "        path variables are passed as arguments, http data is passed as input on stdin"
    echo -e "        ${YELLOW}example${CLEAR}: ${CYAN}command${CLEAR} ${GREEN}/hello/<name>${CLEAR} ${GREEN}./hello.sh${CLEAR}"
    echo -e "            runs './hello <name>' and returns the output"
    echo -e "        ${YELLOW}example${CLEAR}: ${CYAN}command${CLEAR} ${GREEN}/wordcount${CLEAR} ${GREEN}'wc -w'${CLEAR}"
    echo -e "            will run 'wc -w' on the request body and return the result"
    # echo -e "        ${MAGENTA}note${CLEAR}: something"
    echo -e "    ${CYAN}proxy${CLEAR} ${GREEN}<endpoint>${CLEAR} ${GREEN}<target>${CLEAR}"
    echo -e "        forward all requests from this endpoint to the target server"
    echo -e "        ${YELLOW}example${CLEAR}: ${CYAN}proxy${CLEAR} ${GREEN}/proxy${CLEAR} ${GREEN}localhost:8080/api${CLEAR}"
    echo -e "            will forward a request sent to '/proxy/resource'"
    echo -e "            to 'localhost:8080/api/resource' and attach cors headers on the response"
    echo -e "        ${MAGENTA}note${CLEAR}: adds cors headers to relayed responses"
}
