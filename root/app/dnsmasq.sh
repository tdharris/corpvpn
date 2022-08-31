#!/usr/bin/env bash

set -e

source /app/common.sh

start() {
    log info "Starting dnsmasq..."
    dnsmasq --no-daemon --log-queries >/proc/1/fd/1 2>&1 &
    log info "✔ Started dnsmasq, pid:$(pgrep dnsmasq)"
}

stop() {
    local dnsmasq_pid=$(pgrep dnsmasq)
    if [[ -n ${dnsmasq_pid} ]]; then
        log info "Stopping dnsmasq..."
        kill -s SIGINT ${dnsmasq_pid}
        while [[ -e /proc/${dnsmasq_pid} ]]; do sleep 1; done
        log info "✔ Stopped dnsmasq."
    fi
}

"$@"
