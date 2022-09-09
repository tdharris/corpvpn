#!/usr/bin/env bash

set -e

# shellcheck source=common.sh
# shellcheck disable=SC1091
source /app/common.sh

log_prefix="[$(basename "${BASH_SOURCE[0]}")]"

start() {
    log info "$log_prefix Starting microsocks..."
    microsocks -i 127.0.0.1 -p 9118 &
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
