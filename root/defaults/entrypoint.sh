#!/usr/bin/env bash
set -e -u -o pipefail

echo "INFO: Starting privoxy..."
privoxy /config/privoxy/privoxy.conf
echo "INFO: privoxy pid:$(pgrep privoxy)"

echo "INFO: Starting openconnect..."
export servercert="$(\
    yes no | \
    openconnect "${VPN_SERVER}" 2>&1 >/dev/null | \
    grep 'servercert' | \
    cut -d ' ' -f 6)"

# sleep infinity
# wait

echo "${VPN_PASS}" | \
openconnect \
    --passwd-on-stdin \
    --servercert "${servercert}" \
    --script-tun \
    --script "ocproxy -D 9118 -g" \
    --user="${VPN_USER}" \
    --protocol=pulse \
    --authgroup="Smartphone Push" \
    --non-inter \
    "${VPN_SERVER}"

