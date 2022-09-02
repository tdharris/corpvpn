#!/usr/bin/env bash

# shellcheck source=common.sh
# shellcheck disable=SC1091
source /app/common.sh

log_prefix="[$(basename "${BASH_SOURCE[0]}")]"
services=(
    "openconnect"
    "privoxy"
    "microsocks"
    "dnsmasq"
)

# while loop to check ip and port
for svc in "${services[@]}"; do 
    if ! pgrep "$svc" >/dev/null; then
        log info "$log_prefix $svc is not running"
        "/app/$svc.sh" start
        if [[ "$svc" == "openconnect" ]]; then
            source /app/routes.sh
        fi
    fi
done

if [[ -n "${HEALTHCHECK_PUBLIC_IP}" ]]; then
    http_proxy=http://$(hostname -i):${VPN_PRIVOXY_PORT} wget -Y on -q -O - ifconfig.co/ip | grep -v  "${HEALTHCHECK_PUBLIC_IP}" || exit 1
fi
