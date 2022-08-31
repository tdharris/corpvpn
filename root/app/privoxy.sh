#!/usr/bin/env bash

set -e 

source /app/common.sh

start() {
    log info "Starting privoxy..."
    privoxy --no-daemon /config/privoxy/privoxy.conf >/proc/1/fd/1 2>&1 &
    log info "✔ Started privoxy, pid:$(pgrep privoxy)"
}


stop() {
    local privoxy_pid=$(pgrep privoxy)
    if [[ -n ${privoxy_pid} ]]; then
        log info "Stopping privoxy..."
        kill -s SIGINT ${privoxy_pid}
        while [[ -e /proc/${privoxy_pid} ]]; do sleep 1; done
        log info "✔ Stopped privoxy."
    fi
}

"$@"
