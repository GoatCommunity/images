# Author: Goat Project / GoatCommunity
# Profile: light — minimal daily-use toolkit
# Registry:  ghcr.io/goatcommunity/goat:light
# Local tag: goat:light
#
# Build locally:
#   docker build -f light.dockerfile -t goat:light .
#
# Pull from registry:
#   goat install light

FROM debian:12-slim

ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"
ARG BUILD_PROFILE="light"

LABEL org.goat.tag="${TAG}"
LABEL org.goat.version="${VERSION}"
LABEL org.goat.build_date="${BUILD_DATE}"
LABEL org.goat.build_profile="${BUILD_PROFILE}"
LABEL org.goat.app="Goat"
LABEL org.goat.src_repository="https://github.com/GoatCommunity/images"

ENV GOAT_BUILD_TYPE="${VERSION}"
ENV GOAT_START_SHELL="zsh"
ENV GOATOS_IMAGE="goat-${BUILD_PROFILE}"

COPY sources /root/sources/

WORKDIR /root/sources/install

RUN chmod +x entrypoint.sh
RUN ./entrypoint.sh package_base
RUN ./entrypoint.sh package_desktop
RUN ./entrypoint.sh package_light
RUN ./entrypoint.sh post_build

WORKDIR /workspace

ENTRYPOINT ["/.goat/entrypoint.sh"]
