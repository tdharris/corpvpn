# CorpVPN

This connects to the Corporate VPN with an `openconnect` client using the `pulse` protocol with `Smartphone Push` MFA and exposes `http(s)`, `socks5`, `dns` proxies with `privoxy`, `microsocks`, `dnsmasq` to which clients can connect to reach services within the vpn.

## Usage

1. Pre-requisites:

    - `Smartphone Push` MFA Method has been configured for the `VPN_USER` account.
    - [Docker](https://docs.docker.com/engine/install/)
    - [Docker-Compose](https://docs.docker.com/compose/install/)

2. Setup Environment Variables:

    ```console
    cp .env.sample .env
    ```

    ```shell
    DEFAULT_PUID=<uid for user>
    DEFAULT_PGID=<gid for user>

    VPN_SERVER=<vpn server address>
    VPN_USER=<vpn username>
    VPN_PASS=<vpn password>
    HEALTHCHECK_PUBLIC_IP=<your public ip>
    LAN_NETWORK=<lan ipv4 network>/<cidr notation>

    VPN_PRIVOXY_PORT=8118
    VPN_SOCKS_PORT=9118
    DNS_PORT=5354
    ```

3. Run with `docker-compose`:

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

4. Setup clients to connect via proxy provided by the container: `:8118` for `http(s)` or `:9118` for `socks`. See [Configure Clients](#configure-clients) for more details.

5. (*optional*) Validate proxy and vpn connectivity:

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

### Linux

For terminal or shell-based environments, most approaches include forwarding into the proxy with a tool like `ncat`, `netcat`, `nc`, or `corkscrew` on mac OS. There are various versions of these tools, which are similar, but may have differing argument syntaxes. 

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

## Related Links

- [OpenConnect](https://www.infradead.org/openconnect/manual.html) - Multi-protocol VPN client, for Cisco AnyConnect VPNs and others.
- [Privoxy](https://www.privoxy.org/) - non-caching web proxy.
- [Dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html) - local dns server.
- [direnv](https://direnv.net/) - shell extension that can load and unload environment variables.
- [ssh_config](https://man7.org/linux/man-pages/man5/ssh_config.5.html) - linux manual page.
