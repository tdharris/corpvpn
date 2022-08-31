#!/usr/bin/env bash

set -e

source /app/common.sh

start() {
    local -r bind_ip="${1}"

    if [[ -z "${bind_ip}" ]]; then
        fail "Unable to start microsocks, missing bind_ip:${bind_ip}"
    fi

    log info "Starting microsocks..."
    microsocks -i "${bind_ip}" -p 9118 &
    log info "✔ Started microsocks, pid:$(pgrep microsocks)"
}

stop() {
    local microsocks_pid=$(pgrep microsocks)
    if [[ -n ${microsocks_pid} ]]; then
        log info "Stopping microsocks..."
        kill -s SIGTERM ${microsocks_pid};
        while [[ -e /proc/${microsocks_pid} ]]; do sleep 1; done;
        log info "✔ Stopped microsocks.";
    fi
}

"$@"
