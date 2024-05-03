#!/usr/bin/env bash

set -e

# shellcheck source=common.sh
# shellcheck disable=SC1091
source /app/common.sh

log_prefix="[$(basename "${BASH_SOURCE[0]}")]"
GP_PID_FILE="/var/run/gpclient.pid"

start() {

    # Check if process is running. Exit in this case.
    # create the tunnel device if not present
    mkdir -p /dev/net
    [ -c "/dev/net/tun" ] || mknod "/dev/net/tun" c 10 200
    tun_create_exit_code=$?
    if [[ ${tun_create_exit_code} != 0 ]]; then
        fail "$log_prefix Unable to create tun device, try adding docker container option '--device=/dev/net/tun'"
    else
        chmod 600 /dev/net/tun
    fi
    [[ -f ${GP_PID_FILE} ]] && ps -p "$(< ${GP_PID_FILE})" &> /dev/null && log error "$log_prefix GlobalProtect is already running." && exit 0

    # Uncomment to test
    # sleep infinity
    # wait

    log info "$log_prefix Starting globalprotect..."
    echo "${VPN_PASS}" | \
    if ! openconnect \
        --background \
        --pid-file="${GP_PID_FILE}" \
        --interface=tun \
        --non-inter \
        --passwd-on-stdin \
        --disable-ipv6 \
        --user="${VPN_USER}" \
        --protocol=pulse \
        --authgroup="Smartphone Push" \
        --dump-http-traffic \
        --timestamp \
        "${VPN_SERVER}" >/proc/1/fd/1 2>&1; then
        log error "$log_prefix GlobalProtect failed to start!" && rm -f ${GP_PID_FILE} && exit 1
    fi
    globalprotect_pid=$(pgrep globalprotect)
    if [[ -z ${globalprotect_pid} ]]; then
        fail "$log_prefix Failed to start globalprotect. Exiting."
    fi

    log info "$log_prefix Waiting for tun device..."
    retry ifconfig tun >/dev/null
    log info "$log_prefix ✔ Started globalprotect, pid:${globalprotect_pid}"

}

stop() {

    if [[ -f ${GP_PID_FILE} ]] && ps -p "$(< ${GP_PID_FILE})" &> /dev/null; then
        local -r oc_pid="$(< ${GP_PID_FILE})"
        log info "$log_prefix Stopping globalprotect..."
        kill -s SIGINT "${oc_pid}"
        while [[ -e "/proc/${oc_pid}" ]]; do sleep 1; done
        rm -f ${GP_PID_FILE} 2>/dev/null
        log info "$log_prefix ✔ Stopped globalprotect."
    else
        log warn "$log_prefix GlobalProtect is not running."
    fi

}

"$@"
