#!/usr/bin/env bash

set -e

trap 'kill ${!}; stop' SIGTERM SIGINT SIGQUIT SIGHUP ERR
log_prefix="[$(basename "${BASH_SOURCE[0]}")]"
# shellcheck source=../app/common.sh
# shellcheck disable=SC1091
source /app/common.sh

start() {
  log info "$log_prefix Starting services..."
  /app/openconnect.sh start
  # shellcheck source=../app/routes.sh
  # shellcheck disable=SC1091
  source /app/routes.sh
  /app/privoxy.sh start
  # shellcheck disable=SC2154
  /app/microsocks.sh start "${docker_ip}"
  /app/dnsmasq.sh start
  log info "$log_prefix ✔ Successfully started all services."
}

stop() {
  log info "$log_prefix Stopping services..."
  /app/openconnect.sh stop
  /app/privoxy.sh stop
  /app/microsocks.sh stop
  /app/dnsmasq.sh stop
  log info "$log_prefix ✔ Successfully stoped all services."

  exit 143; # SIGTERM
}

start

# wait forever
while true; do
  tail -f /dev/null & wait ${!}
done
