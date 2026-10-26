# Build stage: clone upstream repo
FROM python:3.12-slim AS builder

ARG UPSTREAM_REPO=https://github.com/NickWaterton/samsung-tv-ws-api.git
# Pinned commit: upstream master was rewritten (package renamed to samsungframetv,
# 2026-10), which our patches/rest.py no longer applies to.
ARG UPSTREAM_VERSION=7e7766807da0b048e441eef86e7130a5f5030ed9

WORKDIR /build

COPY patches /patches

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && update-ca-certificates || true \
    && git init -q samsung-tv-ws-api \
    && GIT_SSL_NO_VERIFY=true git -C samsung-tv-ws-api fetch -q --depth 1 ${UPSTREAM_REPO} ${UPSTREAM_VERSION} \
    && git -C samsung-tv-ws-api checkout -q FETCH_HEAD \
    && cp /patches/rest.py samsung-tv-ws-api/samsungtvws/rest.py \
    && rm -rf samsung-tv-ws-api/.git \
    && apt-get purge -y git \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Runtime stage
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy upstream repo from builder
COPY --from=builder /build/samsung-tv-ws-api /app/samsung-tv-ws-api

COPY certs/frame-tv-smartviewsdk.pem /usr/local/share/ca-certificates/frame-tv-smartviewsdk.crt
RUN update-ca-certificates

# Install dependencies
RUN pip install --no-cache-dir -r samsung-tv-ws-api/requirements.txt \
    && pip install --no-cache-dir Pillow

# Install upstream package so `samsungtvws` is importable
RUN pip install --no-cache-dir /app/samsung-tv-ws-api

# Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create non-root user with stable UID/GID (1000) so volume permissions can be managed via fsGroup
RUN groupadd -r -g 1000 appuser && useradd -r -g appuser -u 1000 appuser \
    && chown -R appuser:appuser /app

USER appuser

VOLUME ["/art", "/data"]

HEALTHCHECK --interval=5m --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep -f async_art_update_from_directory.py || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
