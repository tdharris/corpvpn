#!/usr/bin/env bash

set -e

source /app/common.sh

OC_PID_FILE="/var/run/openconnect.pid"

start() {

    # Check if process is running. Exit in this case.
    # create the tunnel device if not present
    mkdir -p /dev/net
    [ -c "/dev/net/tun" ] || mknod "/dev/net/tun" c 10 200
    tun_create_exit_code=$?
    if [[ ${tun_create_exit_code} != 0 ]]; then
        fail "Unable to create tun device, try adding docker container option '--device=/dev/net/tun'"
    else
        chmod 600 /dev/net/tun
    fi
    [[ -f ${OC_PID_FILE} ]] && ps -p $(< ${OC_PID_FILE}) &> /dev/null && log error "Openconnect is already running." && exit 0
    log info "Starting openconnect..."
    log info "Connecting to ${VPN_SERVER} to retrieve server certificate"
    export servercert="$(\
        yes no | \
        openconnect "${VPN_SERVER}" 2>&1 >/dev/null | \
        grep 'servercert' | \
        cut -d ' ' -f 6)"
    if [[ -z "${servecert}" ]]; then
        log error "Failed to retrieve server certificate from ${VPN_SERVER}"
        if [[ -z "${VPN_SERVER_FALLBACK_CERTFICIATE}" ]]; then
            fail "No fallback server certificate provided."
        fi
        log info "Using server certificate: ${VPN_SERVER_FALLBACK_CERTFICIATE}"
        export servercert="${VPN_SERVER_FALLBACK_CERTFICIATE}"
    fi
    log debug "Server certificate: ${servercert}"

    # Uncomment to test
    # sleep infinity
    # wait

    echo "${VPN_PASS}" | \
    openconnect \
        --quiet \
        --background \
        --pid-file="${OC_PID_FILE}" \
        --interface=tun \
        --non-inter \
        --passwd-on-stdin \
        --servercert "${servercert}" \
        --disable-ipv6 \
        --user="${VPN_USER}" \
        --protocol=pulse \
        --authgroup="Smartphone Push" \
        "${VPN_SERVER}" >/proc/1/fd/1 2>&1
    [[ $? -ne 0 ]] && log error "Openconnect failed to start!" && rm -f ${OC_PID_FILE} && exit 1

    openconnect_pid=$(pgrep openconnect)
    if [[ -z ${openconnect_pid} ]]; then
        fail "Failed to start openconnect. Exiting."
    fi

    log info "Waiting for tun device..."
    retry ifconfig tun >/dev/null
    log info "✔ Started openconnect, pid:${openconnect_pid}"

}

stop() {

    if [[ -f ${OC_PID_FILE} ]] && ps -p $(< ${OC_PID_FILE}) &> /dev/null; then
        local -r oc_pid="$(< ${OC_PID_FILE})"
        log info "Stopping openconnect..."
        kill -s SIGINT "${oc_pid}"
        while [[ -e "/proc/${oc_pid}" ]]; do sleep 1; done
        rm -f ${OC_PID_FILE} 2>/dev/null
        log info "✔ Stopped openconnect."
    else
        log warn "Openconnect is not running."
    fi

}

"$@"
