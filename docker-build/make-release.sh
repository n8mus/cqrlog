#!/usr/bin/env bash
# Build a CQRLog Enhanced .deb for Ubuntu / Linux Mint / Debian, from any
# Linux machine that has podman or docker.
#
# The package is built inside an Ubuntu 22.04 container on purpose. A binary
# is tied to the C library it was compiled against, so one built on a
# bleeding-edge distribution (Arch, for instance) refuses to start on Ubuntu
# or Mint. Building against Ubuntu 22.04's older glibc produces a binary that
# runs on 22.04 and everything newer.
#
# Usage:   ./docker-build/make-release.sh
# Output:  dist/cqrlog-enhanced_<version>_<arch>.deb
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$PWD"
OUT="$REPO_ROOT/dist"
IMAGE=cqrlog-enhanced-build

say() { printf '\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n' "$1"; }
die() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }

if   command -v podman >/dev/null; then ENGINE=podman
elif command -v docker >/dev/null; then ENGINE=docker
else die "Neither podman nor docker is installed.
       On Arch:          sudo pacman -S --needed podman
       On Debian/Ubuntu: sudo apt install podman"
fi
say "Using $ENGINE"

say "Building the Ubuntu 22.04 build image (slow the first time, then cached)"
"$ENGINE" build -t "$IMAGE" -f docker-build/Dockerfile docker-build/

mkdir -p "$OUT"
say "Compiling and packaging inside the container"
# The source is mounted read-only and copied inside, so a container build can
# never dirty or clobber the working tree (make clean would otherwise delete
# the host's build products). :z relabels for SELinux hosts, harmless elsewhere.
"$ENGINE" run --rm \
  --entrypoint bash \
  -v "$REPO_ROOT":/build:ro,z \
  -v "$OUT":/out:z \
  "$IMAGE" \
  -c 'cp -a /build /src-rw && cd /src-rw && CQRLOG_OUT_DIR=/out exec bash docker-build/build-deb.sh' \
  || die "The container build failed — see the output above."

say "Done"
ls -lh "$OUT"/*.deb
cat <<'NEXT'

  Install it on Ubuntu / Linux Mint with:

      sudo apt install ./dist/cqrlog-enhanced_*.deb

  Or attach it to a GitHub release:

      gh release upload Enhanced-14 dist/cqrlog-enhanced_*.deb

NEXT
