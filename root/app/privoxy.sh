#!/usr/bin/env bash

set -e 

# shellcheck source=common.sh
# shellcheck disable=SC1091
source /app/common.sh

log_prefix="[$(basename "${BASH_SOURCE[0]}")]"

start() {
    log info "$log_prefix Starting privoxy..."
    privoxy --no-daemon /config/privoxy/privoxy.conf >/proc/1/fd/1 2>&1 &
    log info "$log_prefix ✔ Started privoxy, pid:$(pgrep privoxy)"
}

stop() {
    local privoxy_pid
    privoxy_pid=$(pgrep privoxy)
    if [[ -n ${privoxy_pid} ]]; then
        log info "$log_prefix Stopping privoxy..."
        kill -s SIGINT "${privoxy_pid}"
        while [[ -e /proc/${privoxy_pid} ]]; do sleep 1; done
        log info "$log_prefix ✔ Stopped privoxy."
    fi
}

"$@"
