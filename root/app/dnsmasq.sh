#!/usr/bin/env bash

set -e

# shellcheck source=common.sh
# shellcheck disable=SC1091
source /app/common.sh

log_prefix="[$(basename "${BASH_SOURCE[0]}")]"

start() {
    log info "$log_prefix Starting dnsmasq..."
    dnsmasq --no-daemon --log-queries >/proc/1/fd/1 2>&1 &
    log info "$log_prefix ✔ Started dnsmasq, pid:$(pgrep dnsmasq)"
}

stop() {
    local dnsmasq_pid
    dnsmasq_pid=$(pgrep dnsmasq)
    if [[ -n ${dnsmasq_pid} ]]; then
        log info "$log_prefix Stopping dnsmasq..."
        kill -s SIGINT "${dnsmasq_pid}"
        while [[ -e /proc/${dnsmasq_pid} ]]; do sleep 1; done
        log info "$log_prefix ✔ Stopped dnsmasq."
    fi
}

"$@"
