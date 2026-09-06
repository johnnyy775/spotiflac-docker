# syntax=docker/dockerfile:1

ARG SPOTIFLAC_VERSION=7.2.2


# ---------------------------------------------------------
# Stage 1: download + unpack the correct upstream AppImage
#
# IMPORTANT:
# This stage always runs on the native GitHub build platform.
# We DO NOT execute the target AppImage.
# The AppImage is unpacked as an archive with 7-Zip instead.
# ---------------------------------------------------------
FROM --platform=$BUILDPLATFORM debian:13-slim AS extractor

ARG TARGETARCH
ARG SPOTIFLAC_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        7zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) ASSET="SpotiFLAC.AppImage" ;; \
        arm64) ASSET="SpotiFLAC-ARM.AppImage" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    \
    echo "Downloading SpotiFLAC ${SPOTIFLAC_VERSION} for ${TARGETARCH}: ${ASSET}"; \
    curl -fL \
        "https://github.com/spotbye/SpotiFLAC/releases/download/v${SPOTIFLAC_VERSION}/${ASSET}" \
        -o /tmp/SpotiFLAC.AppImage; \
    \
    mkdir -p /opt/spotiflac; \
    7z x /tmp/SpotiFLAC.AppImage -o/opt/spotiflac >/dev/null; \
    \
    test -f /opt/spotiflac/AppRun; \
    test -f /opt/spotiflac/usr/bin/SpotiFLAC; \
    \
    chmod +x \
        /opt/spotiflac/AppRun \
        /opt/spotiflac/usr/bin/SpotiFLAC; \
    \
    curl -fL \
        "https://raw.githubusercontent.com/spotbye/SpotiFLAC/v${SPOTIFLAC_VERSION}/LICENSE" \
        -o /opt/SpotiFLAC-LICENSE; \
    \
    rm -f /tmp/SpotiFLAC.AppImage


# ---------------------------------------------------------
# Stage 2: web-accessible GUI container
# ---------------------------------------------------------
FROM jlesage/baseimage-gui:debian-13-v4.13.2

ARG SPOTIFLAC_VERSION

# SpotiFLAC needs WebKitGTK.
# surf is the lightweight verification browser and reuses
# the same WebKitGTK engine instead of bringing Chromium.
RUN add-pkg \
        ca-certificates \
        libwebkit2gtk-4.1-0 \
        surf \
        xdg-utils

COPY --from=extractor /opt/spotiflac /opt/spotiflac

COPY --from=extractor /opt/SpotiFLAC-LICENSE \
    /usr/share/licenses/SpotiFLAC/LICENSE

COPY rootfs/ /

RUN chmod +x \
        /startapp.sh \
        /usr/local/bin/spotiflac-browser \
        /opt/spotiflac/AppRun \
        /opt/spotiflac/usr/bin/SpotiFLAC \
    && set-cont-env APP_NAME "SpotiFLAC" \
    && set-cont-env APP_VERSION "${SPOTIFLAC_VERSION}"

ENV BROWSER=/usr/local/bin/spotiflac-browser
