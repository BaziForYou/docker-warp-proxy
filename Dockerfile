ARG DEBIAN_RELEASE=bullseye
FROM docker.io/debian:${DEBIAN_RELEASE}-slim

ARG DEBIAN_RELEASE
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gnupg \
        ca-certificates \
        curl \
        socat && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | \
        gpg --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    ARCH="$(dpkg --print-architecture)" && \
    echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ ${DEBIAN_RELEASE} main" \
        > /etc/apt/sources.list.d/cloudflare-client.list

RUN apt-get update && \
    apt-get install -y --no-install-recommends cloudflare-warp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

EXPOSE 40000/tcp

HEALTHCHECK --interval=15s --timeout=10s --start-period=30s --retries=2 \
  CMD curl -fsSL https://www.cloudflare.com/cdn-cgi/trace \
  -x socks5h://127.0.0.1:40000 >/dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
