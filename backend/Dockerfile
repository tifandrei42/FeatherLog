# Optional self-hosted sync backend for FeatherLog.
# PocketBase = a single Go binary providing DB + auth + REST + realtime.
# This is the "heavyweight DevOps canvas" — containerized, IaC-deployable, monitorable.

FROM alpine:3.20

ARG PB_VERSION=0.22.0

RUN apk add --no-cache ca-certificates unzip wget

WORKDIR /pb

RUN wget -q https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip \
    && unzip pocketbase_${PB_VERSION}_linux_amd64.zip \
    && rm pocketbase_${PB_VERSION}_linux_amd64.zip

EXPOSE 8090

# Health endpoint PocketBase exposes — used by compose + orchestrators
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --spider -q http://localhost:8090/api/health || exit 1

CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8090"]
