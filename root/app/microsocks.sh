#!/usr/bin/env bash

set -e

# shellcheck source=common.sh
# shellcheck disable=SC1091
source /app/common.sh

log_prefix="[$(basename "${BASH_SOURCE[0]}")]"

start() {
    local -r bind_ip="${1}"

    if [[ -z "${bind_ip}" ]]; then
        docker_ip="$(ifconfig eth0 | grep -P -o -m 1 '(?<=inet\s)[^\s]+')"
        bind_ip="${docker_ip}"
        if [[ -z "${bind_ip}" ]]; then
            fail "$log_prefix Unable to start microsocks, missing bind_ip:${bind_ip}"
        fi
    fi

    log info "$log_prefix Starting microsocks..."
    microsocks -i "${bind_ip}" -p 9118 &
    log info "$log_prefix ✔ Started microsocks, pid:$(pgrep microsocks)"
}

stop() {
    local microsocks_pid
    microsocks_pid=$(pgrep microsocks)
    if [[ -n ${microsocks_pid} ]]; then
        log info "$log_prefix Stopping microsocks..."
        kill -s SIGTERM "${microsocks_pid}"
        while [[ -e /proc/${microsocks_pid} ]]; do sleep 1; done;
        log info "$log_prefix ✔ Stopped microsocks.";
    fi
}

"$@"
