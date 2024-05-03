#!/usr/bin/env bash

set -e

# shellcheck source=common.sh
# shellcheck disable=SC1091
source /app/common.sh

log_prefix="[$(basename "${BASH_SOURCE[0]}")]"
OC_PID_FILE="/var/run/openconnect.pid"

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
    [[ -f ${OC_PID_FILE} ]] && ps -p "$(< ${OC_PID_FILE})" &> /dev/null && log error "$log_prefix Openconnect is already running." && exit 0

    log info "$log_prefix Starting openconnect..."
    echo "${VPN_PASS}" | \
    if ! openconnect \
        --background \
        --pid-file="${OC_PID_FILE}" \
        --interface=tun \
        --non-inter \
        --passwd-on-stdin \
        --disable-ipv6 \
        --user="${VPN_USER}" \
        --protocol="${VPN_PROTOCOL:-"pulse"}" \
        --authgroup="${VPN_AUTH_GROUP:-"Smartphone Push"}" \
        --dump-http-traffic \
        --timestamp \
        "${VPN_SERVER}" >/proc/1/fd/1 2>&1; then
        log error "$log_prefix Openconnect failed to start!" && rm -f ${OC_PID_FILE} && exit 1
    fi
    openconnect_pid=$(pgrep openconnect)
    if [[ -z ${openconnect_pid} ]]; then
        fail "$log_prefix Failed to start openconnect. Exiting."
    fi

    log info "$log_prefix Waiting for tun device..."
    retry ifconfig tun >/dev/null
    log info "$log_prefix ✔ Started openconnect, pid:${openconnect_pid}"

}

stop() {

    if [[ -f ${OC_PID_FILE} ]] && ps -p "$(< ${OC_PID_FILE})" &> /dev/null; then
        local -r oc_pid="$(< ${OC_PID_FILE})"
        log info "$log_prefix Stopping openconnect..."
        kill -s SIGINT "${oc_pid}"
        while [[ -e "/proc/${oc_pid}" ]]; do sleep 1; done
        rm -f ${OC_PID_FILE} 2>/dev/null
        log info "$log_prefix ✔ Stopped openconnect."
    else
        log warn "$log_prefix Openconnect is not running."
    fi

}

"$@"
