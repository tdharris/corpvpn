FROM ubuntu:22.04

LABEL org.opencontainers.image.authors = "tdharris"
LABEL org.opencontainers.image.source = "https://github.com/tdharris/corpvpn"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openconnect ocproxy privoxy tini wget && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get remove -fy && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

VOLUME ["/config"] 

COPY root/ /

RUN cp -R /defaults /config && \
    mv /config/docker-entrypoint.sh /docker-entrypoint.sh && \
    chmod +x /config/healthcheck.sh && \
    chmod +x /docker-entrypoint.sh

EXPOSE 9118
EXPOSE 8118

ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]
