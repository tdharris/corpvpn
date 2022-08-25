#!/usr/bin/env sh
http_proxy=http://$(hostname -i):${VPN_PRIVOXY_PORT} wget -Y on -q -O - ifconfig.co/ip | grep -v  "$1" || exit 1