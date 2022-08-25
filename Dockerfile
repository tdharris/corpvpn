FROM ubuntu:22.04

LABEL org.opencontainers.image.authors = "tdharris"
LABEL org.opencontainers.image.source = "https://github.com/tdharris/corpvpn"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openconnect ocproxy privoxy dnsmasq wget && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get remove -fy && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

COPY root/ /

RUN mkdir -p /config/{openconnect,privoxy} && \
    cp -R /defaults/privoxy /config/privoxy && \
    cp -R /defaults/openconnect /config/openconnect && \
    cp /defaults/healthcheck.sh /config/healthcheck.sh && \
    cp /defaults/entrypoint.sh /entrypoint.sh && \
    chmod +x /config/healthcheck.sh && \
    chmod +x /entrypoint.sh

EXPOSE 9118
EXPOSE 8118

VOLUME [ "/config" ]

ENTRYPOINT [ "/entrypoint.sh" ]
