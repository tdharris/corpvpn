FROM ubuntu:24.04

LABEL org.opencontainers.image.authors = "tdharris"
LABEL org.opencontainers.image.source = "https://github.com/tdharris/corpvpn"
LABEL org.opencontainers.image.description = "OpenConnect VPN client with Privoxy, Microsocks, and DNSMasq"

ARG INSTALL_OT_GLOBAL_PROTECT=true

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openconnect iproute2 privoxy tini wget dnsmasq \
        dnsutils net-tools curl jq build-essential ca-certificates && \
    apt-get update && \
    apt-get upgrade -y

# GLOBAL PROTECT (gpclient): Required the following:
# sudo apt --fix-broken install (+500MB) + requires interactivity? (US + Denver)
# - /usr/bin/gpauth reports "cannot be run as root", to run with "sudo" need it installed:
# apt-get update && \
# apt-get -y install sudo
RUN if [[ "$INSTALL_OT_GLOBAL_PROTECT" == "true" ]]; then \
        apt --fix-broken install -y && \
        wget https://github.com/yuezk/GlobalProtect-openconnect/releases/download/v2.1.0/globalprotect-openconnect_2.1.0-1_amd64.deb && \
        dpkg -i globalprotect-openconnect_2.1.0-1_amd64.deb && \
        rm globalprotect-openconnect_2.1.0-1_amd64.deb; \
    fi

# sudo apt-get install gir1.2-gtk-3.0 gir1.2-webkit2-4.0 && \
#     sudo add-apt-repository ppa:yuezk/globalprotect-openconnect && \  # add-apt-repository: command not found
#     sudo apt-get update && \
#     sudo apt-get install globalprotect-openconnect;

RUN mkdir -p /tmp/microsocks && cd /tmp/microsocks && \
    curl -s https://api.github.com/repos/rofl0r/microsocks/releases/latest | jq -r '.tarball_url' | \
        xargs wget -O - | tar xz --transform 's/^rofl0r-microsocks.*\///' -C . && \
    make install && \
    rm -rf /tmp/microsocks

RUN apt-get remove -fy && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

RUN groupadd -r app && useradd -r -g app app
USER app

VOLUME ["/config"] 

COPY root/ /

RUN cp -R /defaults /config && \
    mv /config/docker-entrypoint.sh /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

EXPOSE 8118
EXPOSE 9118

ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]
