# CorpVPN

This connects to the corporate vpn with `openconnect` using the `pulse` protocol with `Smartphone Push` MFA and exposes a proxy with `privoxy` to which clients can connect.

## Usage

1. Setup Environment Variables:

    ```console
    cp .env.sample .env
    ```

2. Run:

    ```console
    docker-compose up
    ```
    ```console
    docker-compose up -d
    ```

3. Setup browser or other clients to connect via proxy: http `:8118` or socks `:9118`.

## Related Links

- https://www.infradead.org/openconnect/manual.html
- https://www.privoxy.org/
