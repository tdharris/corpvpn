FROM ubuntu:24.04

LABEL org.opencontainers.image.authors = "tdharris"
LABEL org.opencontainers.image.source = "https://github.com/tdharris/corpvpn"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openconnect iproute2 privoxy tini wget dnsmasq \
        dnsutils net-tools curl jq build-essential ca-certificates && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get remove -fy && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

RUN mkdir -p /tmp/microsocks && cd /tmp/microsocks && \
    curl -s https://api.github.com/repos/rofl0r/microsocks/releases/latest | jq -r '.tarball_url' | \
        xargs wget -O - | tar xz --transform 's/^rofl0r-microsocks.*\///' -C . && \
    make install && \
    rm -rf /tmp/microsocks

VOLUME ["/config"] 

COPY root/ /

RUN cp -R /defaults /config && \
    mv /config/docker-entrypoint.sh /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

EXPOSE 8118
EXPOSE 9118

ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]
