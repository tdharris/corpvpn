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

ENABLE_VPN="${1:-false}"
ENABLE_DNS="${2:-false}"
AUTO_RESTART_SERVICES="${3:-false}"

for svc in "${services[@]}"; do
    if [[ "$svc" == "openconnect" && ! "$ENABLE_VPN" == "true" ]]; then
        continue
    elif [[ "$svc" == "dnsmasq" && ! "$ENABLE_DNS" == "true" ]]; then
        continue
    fi

    if ! pgrep "$svc" >/dev/null; then
        log info "$log_prefix $svc is not running"
        if "$AUTO_RESTART_SERVICES"; then
            "/app/$svc.sh" start
            if [[ "$svc" == "openconnect" ]]; then
                source /app/routes.sh
            fi
        fi
    fi
done

if [[ "$ENABLE_VPN" == "true" ]]; then
    vpn_ip="$(ifconfig tun | grep -P -o -m 1 '(?<=inet\s)[^\s]+')"
    [[ -z "${vpn_ip}" ]] && fail "$log_prefix tun device not found!"
    ip_check="$(wget -Y on -q -O - ifconfig.co/ip)"
    echo "${ip_check}" | grep -q "${vpn_ip}" || fail "$log_prefix ip check failed - found ${ip_check} instead of ${vpn_ip}!"
else
    return 0
fi
