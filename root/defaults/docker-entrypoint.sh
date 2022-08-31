#!/usr/bin/env bash

set -e

trap 'kill ${!}; stop' SIGTERM SIGINT SIGQUIT SIGHUP ERR

source /app/common.sh

start() {
    log info "Starting services..."
    /app/openconnect.sh start
    source /app/routes.sh
    /app/privoxy.sh start
    /app/microsocks.sh start "${docker_ip}"
    /app/dnsmasq.sh start
    log info "✔ Successfully started all services."
}

stop() {
    log info "Stopping services..."
    /app/openconnect.sh stop
    /app/privoxy.sh stop
    /app/microsocks.sh stop
    /app/dnsmasq.sh stop
    log info "✔ Successfully stoped all services."

    exit 143; # SIGTERM
}

start

# wait forever
while true; do
  tail -f /dev/null & wait ${!}
done
