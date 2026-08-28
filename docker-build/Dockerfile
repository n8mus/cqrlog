# Build environment for CQRLog Enhanced release packages.
#
# Ubuntu 22.04 on purpose: a compiled binary is tied to the C library it was
# built against, so it runs on that release and newer ones but not older. 22.04
# covers Ubuntu 22.04+, Linux Mint 21+ and Debian 12+ from a single build.
#
# Driven by docker-build/make-release.sh — deliberately no ENTRYPOINT, so the
# caller decides what to run.
FROM ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
      git make ca-certificates \
      lazarus lcl lcl-gtk2 lcl-units lcl-utils \
      fpc fpc-source fp-units-rtl fp-units-misc fp-units-gfx fp-units-gtk2 \
      fp-units-db fp-units-math fp-units-net \
      libssl-dev libgtk2.0-dev \
      dpkg-dev fakeroot \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src-rw
