# CorpVPN Proxy

<img src="img/corpvpn.webp" height="300">

![](https://img.shields.io/github/license/tdharris/corpvpn)
![](https://img.shields.io/github/last-commit/tdharris/corpvpn)
![](https://img.shields.io/github/actions/workflow/status/tdharris/corpvpn/docker-publish.yml)
![](https://img.shields.io/docker/image-size/tdharris/corpvpn/latest)

This `docker-compose` project provides a way to connect to a Corporate VPN and expose `http(s)`, `socks5`, `dns` proxies. It supports two approaches:

1. **Proxy Using Host's VPN**: The container leverages the host's existing VPN connection.
2. **Self-Contained VPN**: The container connects to the VPN using `openconnect`, creating a self-contained setup.

Both approaches provide proxy services (`http(s)`, `socks5`, `dns`) with `privoxy`, `microsocks`, `dnsmasq` for clients to reach services within the VPN. Choose an approach based on your requirements and VPN server capabilities.

## Usage

To help you get started creating a container from this image you can use docker-compose or the docker cli.

### docker-compose (recommended)

```yaml
---
version: "3.3"
services:
  corpvpn:
    image: tdharris/corpvpn:latest
    container_name: corpvpn
    cap_add:
      - NET_ADMIN
    volumes:
      - /etc/localtime:/etc/localtime:ro
    env_file: .env
    ports:
      - ${VPN_PRIVOXY_PORT}:8118
      - ${VPN_SOCKS_PORT}:9118
      - ${DNS_PORT}:53/tcp
      - ${DNS_PORT}:53/udp
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=0
      - net.ipv6.conf.default.disable_ipv6=0
      - net.ipv6.conf.lo.disable_ipv6=0
      - net.ipv4.tcp_keepalive_intvl=1
      - net.ipv4.tcp_keepalive_probes=3
      - net.ipv4.tcp_keepalive_time=30
    logging:
      driver: "json-file"
      options:
        max-size: "10M"
        max-file: "10"
    healthcheck:
      test: /app/healthcheck.sh "${ENABLE_VPN}" "${ENABLE_DNS}" "${AUTO_RESTART_SERVICES}" || exit 1
      timeout: 30s
      interval: 5m
      start_period: 60s
      retries: 2
```

- See [.env.sample⁠](.env.sample) for Environment Variables. Review usage approaches⁠ below for additional information.
- See [Docker Hub tdharris/corpvpn](https://hub.docker.com/r/tdharris/corpvpn) for more information on the image. You can also build the image locally with the provided Dockerfile.

### Approach 1: Proxy Leveraging Host's Network

In this approach, the Docker container acts as a proxy that leverages the host's network connection to the Corporate VPN. This is a simpler setup where the host machine is already connected to the Corporate VPN, and the Docker container simply provides proxy services (http(s), socks5, dns) to other clients to reach services within the VPN.

To use this approach, you would run the docker-compose setup as usual, without needing to provide VPN connection details. The container will use the host's VPN connection to access the corporate network.

1. Pre-requisites:

    - The host machine is already connected to the Corporate VPN.
    - [Docker](https://docs.docker.com/engine/install/)
    - [Docker-Compose](https://docs.docker.com/compose/install/)

2. Setup Environment Variables:

    ```console
    cp .env.sample .env
    ```

    Update the following in the `.env` file:

    ```shell
    ENABLE_VPN=false
    LAN_NETWORK=<lan ipv4 network>/<cidr notation>
    ```

3. See [Common Steps for Both Approaches](#common-steps-for-both-approaches) below.

### Approach 2: Self-Contained VPN Connection

In this approach, the Docker container connects to the Corporate VPN using `openconnect` and with a configurable protocol. This creates a self-contained setup where the VPN connection is managed within the Docker container itself. This approach is more complex and requires the VPN server to support connections from `openconnect` with the possibility of using MFA methods like `Smartphone Push`.

To use this approach, you would need to provide the VPN connection details (`VPN_SERVER`, `VPN_USER`, `VPN_PASS`, `VPN_PROTOCOL`, `VPN_AUTH_GROUP`). The container will use these details to establish its own VPN connection.

Please note that not all VPN servers support connections from `openconnect`. Check with your IT department or VPN provider to see if this approach is permitted.

1. Pre-requisites:

    - `Smartphone Push` MFA Method has been configured for the `VPN_USER` account. (Configurable with `VPN_AUTH_GROUP`)
    - [Docker](https://docs.docker.com/engine/install/)
    - [Docker-Compose](https://docs.docker.com/compose/install/)

2. Setup Environment Variables:

    ```console
    cp .env.sample .env
    ```

    Update the following in the `.env` file:

    ```shell
    ENABLE_VPN=true
    VPN_SERVER=<vpn server address>
    VPN_USER=<vpn username>
    VPN_PASS=<vpn password>
    LAN_NETWORK=<lan ipv4 network>/<cidr notation>
    ```

3. See [Common Steps for Both Approaches](#common-steps-for-both-approaches) below.

### Common Steps for Both Approaches

After setting up the pre-requisites and environment variables above, follow these steps to run the `docker-compose` setup:

1. Run with `docker-compose`:

    ```console
    docker-compose up -d
    ```

    - Approve MFA request via `Smartphone Push`.
    - To monitor container logs:

        ```shell
        docker logs -f --tail 10 corpvpn
        ```
    - To stop the vpn, simply stop the container:

        ```shell
        docker stop corpvpn
        ```

2. Setup clients to connect via proxy provided by the container: `:8118` for `http(s)` or `:9118` for `socks`. See [Configure Clients](#configure-clients) for more details.

3. (*optional*) Validate proxy and vpn connectivity:

    To validate the `http(s)` `:8118` and `socks` `:9118` proxies, the following commands should be successful and return the vpn ip address, not your public ip address:

    ```shell
    curl -sSf --socks5 127.0.0.1:9118 ifconfig.co/ip
    curl -sSf --proxy 127.0.0.1:8118 ifconfig.co/ip
    ```

    **Note** : Replace `127.0.0.1` with the host ip address where the container is running if not localhost.

## Configure Clients

Configure clients as an opt-in approach to forward requests in through the proxy to the corporate network.

### Browsers / OS

- [Chrome, Firefox, Edge, Opera](https://www.digitalcitizen.life/how-set-proxy-server-all-major-internet-browsers-windows/)
- [Safari](https://support.apple.com/guide/safari/set-up-a-proxy-server-ibrw1053/mac)
- [Windows](https://support.microsoft.com/en-us/windows/use-a-proxy-server-in-windows-03096c53-0554-4ffe-b6ab-8b1deee8dae1)
- [Mac](https://support.apple.com/guide/mac-help/enter-proxy-server-settings-on-mac-mchlp25912/mac)
- [Linux Ubuntu](https://help.ubuntu.com/stable/ubuntu-help/net-proxy.html.en)

### Linux

The following are options for other client-based approaches:

- [Environment Variables](#environment-variables)
- [SSH](#ssh)
- [GIT](#git)

#### Pre-Requisites

For terminal or shell-based environments, most approaches include forwarding into the proxy with a tool like `ncat`, `netcat`, `nc`, or optionally `corkscrew` on mac OS. There are various versions of these tools, which are similar, but likely have different arguments or syntaxes. 

Recommend installing the following with `brew` which includes `ncat`, which is referenced in the below examples or install directly as needed:

```shell
brew install nmap
```
```shell
ncat --version
Ncat: Version 7.93 ( https://nmap.org/ncat )
```

#### Environment Variables

The `http_proxy` and `https_proxy` environment variables are used to specify proxy settings to various client programs such as `curl`, `wget`, etc.

```shell
export {http,https}_proxy=http://127.0.0.1:8118
```

To setup permanently, use `/etc/environment`:
```shell
echo "http_proxy=http://127.0.0.1:8118" >> /etc/environment
echo "https_proxy=http://127.0.0.1:8118" >> /etc/environment
```

To setup dynamically based on `pwd`, consider using [direnv](https://direnv.net/) to create an `.envrc` file at the base directory where vpn connections should occur by default. This will then load and unload these env vars automatically depending on the working directory.

```shell
# .envrc
export {http,https}_proxy=http://127.0.0.1:8118
```

To verify the configuration is working with these env vars set, the following should return the vpn ip address and not your public ip address:

```shell
curl ifconfig.co/ip
<corpvpn ip address>
```

#### SSH

To `ssh` through the proxy, or for `git` operations that may rely on `ssh`, consider the following manual example:
```shell
# via http
ssh -o "ProxyCommand=ncat --proxy 127.0.0.1:8118 --proxy-type http %h %p" user@host

# via socks5
ssh -o "ProxyCommand=ncat --proxy 127.0.0.1:9118 --proxy-type socks5 %h %p" user@host
```

To automate these connections based on the host or domain, define with `ProxyCommand` within `~/.ssh/config`:
```shell
Host <hostname>
  ProxyCommand ncat --proxy 127.0.0.1:8118 --proxy-type http %h %p
  # ProxyCommand ncat --proxy 127.0.0.1:9118 --proxy-type socks5 %h %p
```

```shell
# wildcard
Host *.<hostname>
  ProxyCommand ncat --proxy 127.0.0.1:8118 --proxy-type http %h %p
  # ProxyCommand ncat --proxy 127.0.0.1:9118 --proxy-type socks5 %h %p
```

#### GIT

To configure connections for `git` through the proxy:

- For `ssh` connectivity, see [SSH](#ssh) above.

- For `http(s)` connectivity:

    Global proxy:

    ```shell
    git config --global http.proxy http://127.0.0.1:8118
    git config --global https.proxy https://127.0.0.1:8118
    ```

    URL specific proxy:

    ```shell
    git config --global http.http://domain.com.proxy http://127.0.0.1:8118
    git config --global https.https://domain.com.proxy https://127.0.0.1:8118
    ```

    **Note** : The above url-specific syntax is a bit strange, but generates the following in `~/.gitconfig`:

    ```shell
    [http]
    [http "http://domain.com"]
        proxy = http://127.0.0.1:8118
    [https "https://domain.com"]
        proxy = https://127.0.0.1:8118
    ```

## Related Links

- [OpenConnect](https://www.infradead.org/openconnect/manual.html) - Multi-protocol VPN client, for Cisco AnyConnect VPNs and others.
- [Privoxy](https://www.privoxy.org/) - non-caching web proxy.
- [MicroSocks](https://github.com/rofl0r/microsocks) - multithreaded, small, efficient SOCKS5 server.
- [Dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html) - local dns server.
- [direnv](https://direnv.net/) - shell extension that can load and unload environment variables.
- [ssh_config](https://man7.org/linux/man-pages/man5/ssh_config.5.html) - linux manual page.