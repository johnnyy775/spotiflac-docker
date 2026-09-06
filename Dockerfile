# syntax=docker/dockerfile:1

ARG SPOTIFLAC_VERSION=7.2.2

# ---------------------------------------------------------
# Stage 1: download + unpack the correct upstream AppImage
# ---------------------------------------------------------
FROM --platform=$TARGETPLATFORM debian:13-slim AS extractor

ARG TARGETARCH
ARG SPOTIFLAC_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) ASSET="SpotiFLAC.AppImage" ;; \
        arm64) ASSET="SpotiFLAC-ARM.AppImage" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fL \
        "https://github.com/spotbye/SpotiFLAC/releases/download/v${SPOTIFLAC_VERSION}/${ASSET}" \
        -o SpotiFLAC.AppImage; \
    chmod +x SpotiFLAC.AppImage; \
    ./SpotiFLAC.AppImage --appimage-extract >/dev/null; \
    mv squashfs-root /opt/spotiflac; \
    curl -fL \
        "https://raw.githubusercontent.com/spotbye/SpotiFLAC/v${SPOTIFLAC_VERSION}/LICENSE" \
        -o /opt/SpotiFLAC-LICENSE


# ---------------------------------------------------------
# Stage 2: web-accessible GUI container
# ---------------------------------------------------------
FROM jlesage/baseimage-gui:debian-13-v4.13.2

ARG SPOTIFLAC_VERSION

# SpotiFLAC already needs WebKitGTK.
# surf is our tiny verification browser using the SAME engine.
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
