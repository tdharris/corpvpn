#!/usr/bin/env bash

set -e

trap 'kill ${!}; stop' SIGTERM SIGINT SIGQUIT SIGHUP ERR

function log { local -r level="$1"; shift; echo -e "[${level^^}] [docker-entrypoint.sh] $(date '+%Y-%m-%d %H:%M:%S.%3N') $*" >/proc/1/fd/1 2>&1; }

OC_PID_FILE="/var/run/openconnect.pid"

start() {
    # Privoxy
    log info "Starting privoxy..."
    privoxy --no-daemon /config/privoxy/privoxy.conf >/proc/1/fd/1 2>&1 &
    privoxy_pid=$(pgrep privoxy)
    log info "✔ Started privoxy, pid:$privoxy_pid"

    # dnsmasq
    log info "Starting dnsmasq..."
    dnsmasq --no-daemon --log-queries >/proc/1/fd/1 2>&1 &
    dnsmasq_pid=$(pgrep dnsmasq)
    log info "✔ Started dnsmasq, pid:$dnsmasq_pid"

    # OpenConnect
    # Check if process is running. Exit in this case.
    [[ -f ${OC_PID_FILE} ]] && ps -p $(< ${OC_PID_FILE}) &> /dev/null && log error "Openconnect is already running." && exit 0
    log info "Starting openconnect..."
    log info "Connecting to ${VPN_SERVER}"
    export servercert="$(\
        yes no | \
        openconnect "${VPN_SERVER}" 2>&1 >/dev/null | \
        grep 'servercert' | \
        cut -d ' ' -f 6)"
    log debug "Server certificate: ${servercert}"

    # Uncomment to test
    # sleep infinity
    # wait

    echo "${VPN_PASS}" | \
    openconnect \
        --background \
        --pid-file="${OC_PID_FILE}" \
        --non-inter \
        --passwd-on-stdin \
        --servercert "${servercert}" \
        --script-tun \
        --script "ocproxy -D 9118 -g" \
        --disable-ipv6 \
        --user="${VPN_USER}" \
        --protocol=pulse \
        --authgroup="Smartphone Push" \
        "${VPN_SERVER}" >/proc/1/fd/1 2>&1
    [[ $? -ne 0 ]] && log error "Openconnect failed to start!" && rm -f ${OC_PID_FILE} && exit 1
    
    openconnect_pid=$(pgrep openconnect)
    if [[ -z $openconnect_pid ]]; then
        log error "Failed to start openconnect. Exiting."
        exit 1
    fi

    log info "✔ Started openconnect, pid:$openconnect_pid"
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

    local privoxy_pid=$(pgrep privoxy)
    if [[ -n $privoxy_pid ]]; then
        log info "Stopping privoxy..."
        kill -s SIGINT $privoxy_pid
        while [[ -e /proc/$privoxy_pid ]]; do sleep 1; done
        log info "✔ Stopped privoxy."
    fi

    local dnsmasq_pid=$(pgrep dnsmasq)
    if [[ -n $dnsmasq_pid ]]; then
        log info "Stopping dnsmasq..."
        kill -s SIGINT $dnsmasq_pid
        while [[ -e /proc/$dnsmasq_pid ]]; do sleep 1; done
        log info "✔ Stopped dnsmasq."
    fi
    
    exit 143; # SIGTERM
}

start

# wait forever
while true; do
  tail -f /dev/null & wait ${!}
done
