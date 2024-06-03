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

ENABLE_VPN="${1:-${ENABLE_VPN:-false}}"
ENABLE_DNS="${2:-${ENABLE_DNS:-false}}"
AUTOHEAL_ENABLED="${3:-${AUTOHEAL_ENABLED:-false}}"

max_retries=3
state_dir="/app/state"
mkdir -p $state_dir 2>/dev/null

for svc in "${services[@]}"; do
    if [[ "$svc" == "openconnect" && ! "$ENABLE_VPN" == "true" ]]; then
        continue
    elif [[ "$svc" == "dnsmasq" && ! "$ENABLE_DNS" == "true" ]]; then
        continue
    fi
    
    if ! pgrep "$svc" >/dev/null; then
        state_file="$state_dir/$svc.state"
        if [[ -f "$state_file" ]]; then
            retries=$(cat "$state_file")
            if [[ "$retries" -ge $max_retries ]]; then
                log error "$log_prefix $svc failed to start after $max_retries retries, exiting"
                exit 1
            fi
        else
            retries=0
        fi
        log info "$log_prefix $svc is not running"
        if "$AUTOHEAL_ENABLED"; then
            "/app/$svc.sh" start
            if [[ "$svc" == "openconnect" ]]; then
                source /app/routes.sh
            fi
            retries=$((retries + 1))
            echo "$retries" > "$state_file"
        fi
    fi
done

if [[ "$ENABLE_VPN" == "true" ]]; then
    vpn_ip="$(ifconfig tun | grep -P -o -m 1 '(?<=inet\s)[^\s]+')"
    [[ -z "${vpn_ip}" ]] && fail "$log_prefix tun device not found!"
    ip_check="$(wget -Y on -q -O - ifconfig.co/ip)"
    echo "${ip_check}" | grep -q "${vpn_ip}" || fail "$log_prefix ip check failed - found ${ip_check} instead of ${vpn_ip}!"
else
    exit 0
fi
