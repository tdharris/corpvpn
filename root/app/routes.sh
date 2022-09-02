#!/usr/bin/env bash

set -e

# shellcheck source=common.sh
# shellcheck disable=SC1091
source /app/common.sh

lp="[$(basename "${BASH_SOURCE[0]}")]"

# Identify current default routes
docker_interface="$(ip -4 route ls | grep default | xargs | grep -o -P '[^\s]+$')"
docker_ip="$(ifconfig "${docker_interface}" | grep -P -o -m 1 '(?<=inet\s)[^\s]+')"
docker_gw="$(ip route show default | awk '/default/ {print $3}')"
log debug "$lp docker_interface:${docker_interface} docker_ip:${docker_ip} docker_gw:${docker_gw}"

vpn_ip="$(ifconfig tun | grep -P -o -m 1 '(?<=inet\s)[^\s]+')"
vpn_gw="$(ip route show "${vpn_ip}" | awk '{print $1}')"
log debug "$lp vpn_ip:${vpn_ip} vpn_gw:${vpn_gw}"

log info "$lp Setting up default route through ${vpn_gw}"
route -v add default gw "${vpn_gw}" >/proc/1/fd/1 2>&1
route -v del -net 0.0.0.0 gw "${docker_gw}" netmask 0.0.0.0 dev "${docker_interface}" >/proc/1/fd/1 2>&1

# Lan Networks
# split comma separated string into array from LAN_NETWORK env variable
IFS=',' read -ra lan_array <<< "${LAN_NETWORK}"

# process lan networks in the array
for lan_item in "${lan_array[@]}"; do
    # cleanup whitespace
    lan_item="$(echo "${lan_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')"
    log info "$lp Adding LAN_NETWORK ${lan_item} as route via docker ${docker_interface}"
    ip route add "${lan_item}" via "${docker_gw}" dev "${docker_interface}" >/proc/1/fd/1 2>&1
done
