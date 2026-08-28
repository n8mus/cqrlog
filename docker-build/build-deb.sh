#!/usr/bin/env bash
# Runs INSIDE the Ubuntu build container. Compiles CQRLog Enhanced and
# assembles a .deb for Ubuntu / Linux Mint / Debian.
#
# Not meant to be run by hand — use ../docker-build/make-release.sh on the host.
#
# We assemble the package with dpkg-deb rather than dpkg-buildpackage: the
# in-tree debian/ directory is upstream's, pinned to debhelper compat 7, and
# lists build-time -dev packages as runtime Depends (including
# libmariadbclient-dev-compat, which no longer exists on modern Ubuntu). Doing
# it directly lets us state the real runtime dependencies and let
# dpkg-shlibdeps compute the library ones.
set -euo pipefail

SRC=/build
OUT=/out
PKGROOT=/tmp/pkgroot

say() { printf '\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n' "$1"; }

cd "$SRC"

# ---- version ---------------------------------------------------------------
# src/uVersion.pas holds e.g.  cVersionBase = 'Enhanced_(14)_'
ENH="$(sed -n "s/.*cVersionBase.*'Enhanced_(\([0-9]\+\))_'.*/\1/p" src/uVersion.pas | head -1)"
[ -n "$ENH" ] || { echo "ERROR: could not parse the version from src/uVersion.pas" >&2; exit 1; }
# Upstream base version, so the package sorts above distro cqrlog (2.6.x).
DEBVER="2.6.0+enhanced${ENH}-1"
ARCH="$(dpkg --print-architecture)"
say "Building CQRLog Enhanced ($ENH) -> version $DEBVER, arch $ARCH"

# ---- compile ---------------------------------------------------------------
say "Compiling"
make clean >/dev/null 2>&1 || true
make cqrlog
[ -x src/cqrlog ] || { echo "ERROR: build produced no src/cqrlog" >&2; exit 1; }

# ---- lay out the install tree ---------------------------------------------
say "Installing into a staging tree"
rm -rf "$PKGROOT"
mkdir -p "$PKGROOT/usr" "$PKGROOT/DEBIAN"
make DESTDIR="$PKGROOT/usr" install

# ---- dependencies ----------------------------------------------------------
# Let dpkg-shlibdeps work out the shared-library deps from the binary itself.
say "Computing library dependencies"
mkdir -p "$PKGROOT/debian"
: > "$PKGROOT/debian/control"     # dpkg-shlibdeps insists on this existing
SHLIBDEPS=""
if ( cd "$PKGROOT" && dpkg-shlibdeps -O --ignore-missing-info usr/bin/cqrlog 2>/dev/null ) > /tmp/shlibs.txt; then
  SHLIBDEPS="$(sed -n 's/^shlibs:Depends=//p' /tmp/shlibs.txt)"
fi
rm -rf "$PKGROOT/debian"
if [ -z "$SHLIBDEPS" ]; then
  echo "    shlibdeps found nothing usable; falling back to a known-good set"
  SHLIBDEPS="libc6, libgtk2.0-0, libssl3"
fi
echo "    library deps: $SHLIBDEPS"

# Runtime programs CQRLOG actually needs beyond libraries. The database
# packages matter most: without them the logger has nothing to store QSOs in.
RUNDEPS="mariadb-server, mariadb-client"

cat > "$PKGROOT/DEBIAN/control" <<CONTROL
Package: cqrlog-enhanced
Version: $DEBVER
Section: hamradio
Priority: optional
Architecture: $ARCH
Depends: $SHLIBDEPS, $RUNDEPS
Recommends: libhamlib-utils, trustedqsl, xplanet
Conflicts: cqrlog
Replaces: cqrlog
Provides: cqrlog
Maintainer: Jon, N8EM <jon5520@gmail.com>
Homepage: https://github.com/n8mus/cqrlog
Description: Advanced ham radio logger - Enhanced fork with POTA and auto-QSL
 CQRLog Enhanced is a fork of CQRLOG for Linux amateur radio operators,
 adding Parks on the Air (POTA) logging and live POTA spots, automatic
 LoTW, eQSL and QRZ.com upload with daily confirmation download, clearer
 DX-cluster colours, and support for modern MariaDB installations.
 .
 It provides rig control via hamlib, DX cluster connection, HamQTH/QRZ
 callbook lookup, a grayliner, QSL manager database and country
 resolution based on the OK1RR country tables.
 .
 Based on CqrlogAlpha by Saku OH1KH, itself a fork of CQRLOG by
 Petr OK2CQR.
CONTROL

# ---- maintainer scripts ----------------------------------------------------
# The whole point of this fork: make the database work on a modern system.
# Do it at install time so the user never meets the "can't connect to local
# MySQL server" wall in the first place.
cat > "$PKGROOT/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e

# CQRLOG looks for a server binary named 'mysqld'; modern MariaDB ships only
# 'mariadbd' and most distributions dropped the compatibility name.
if ! command -v mysqld >/dev/null 2>&1 && [ ! -e /usr/sbin/mysqld ]; then
  MARIADBD="$(command -v mariadbd 2>/dev/null || true)"
  [ -n "$MARIADBD" ] || [ ! -e /usr/sbin/mariadbd ] || MARIADBD=/usr/sbin/mariadbd
  if [ -n "$MARIADBD" ]; then
    ln -sf "$MARIADBD" /usr/sbin/mysqld
    echo "cqrlog-enhanced: linked mysqld -> $MARIADBD"
  fi
fi

# AppArmor blocks the database directory under the user's home on
# Debian/Ubuntu unless told otherwise.
for prof in usr.sbin.mariadbd usr.sbin.mysqld; do
  if [ -e "/etc/apparmor.d/$prof" ]; then
    mkdir -p /etc/apparmor.d/local
    LOCAL="/etc/apparmor.d/local/$prof"
    if ! grep -q "cqrlog/database" "$LOCAL" 2>/dev/null; then
      printf '  @{HOME}/.config/cqrlog/database/ r,\n  @{HOME}/.config/cqrlog/database/** rwk,\n' >> "$LOCAL"
    fi
    apparmor_parser -r "/etc/apparmor.d/$prof" 2>/dev/null || true
  fi
done

exit 0
POSTINST
chmod 0755 "$PKGROOT/DEBIAN/postinst"

# ---- build it --------------------------------------------------------------
say "Assembling the package"
find "$PKGROOT/usr" -type d -exec chmod 0755 {} +
chown -R root:root "$PKGROOT" 2>/dev/null || true
mkdir -p "$OUT"
DEB="$OUT/cqrlog-enhanced_${DEBVER}_${ARCH}.deb"
dpkg-deb --build --root-owner-group "$PKGROOT" "$DEB"

say "Verifying"
dpkg-deb --info "$DEB"
dpkg-deb --contents "$DEB" | head -15
echo "    ..."
echo
echo "Built: $DEB"
