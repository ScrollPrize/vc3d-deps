# syntax=docker/dockerfile:1.7

FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

LABEL org.opencontainers.image.source="https://github.com/ScrollPrize/vc3d-deps"
LABEL org.opencontainers.image.description="VC3D CI dependencies for Ubuntu 26.04"

COPY install-deps.sh /usr/local/sbin/install-vc3d-deps

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    /usr/local/sbin/install-vc3d-deps \
 && rm -f /usr/local/sbin/install-vc3d-deps

WORKDIR /workspace

