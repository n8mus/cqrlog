#!/usr/bin/env bash
# CQRLog Enhanced — one-shot installer for Linux.
#
# Does the whole job, start to finish:
#   1. installs the build tools for your distro (Debian/Ubuntu/Mint, Arch, Fedora)
#   2. downloads the CQRLog Enhanced source
#   3. compiles it
#   4. installs the program AND its data files (country files, help, icons, globe)
#   5. sets up the MariaDB database and fixes the "can't connect to MySQL" wall
#
# Run it as your normal user; it will ask for your password when it needs sudo.
# Safe to re-run — that is also how you upgrade to the latest version.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/n8mus/cqrlog/master/install-cqrlog.sh)
#
# 73 de N8EM
set -euo pipefail

REPO="https://github.com/n8mus/cqrlog.git"
SRCDIR="${CQRLOG_SRC:-$HOME/cqrlog-enhanced}"

say()  { printf '\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n' "$1"; }
info() { printf '    %s\n' "$1"; }
warn() { printf '\033[1;33m!   %s\033[0m\n' "$1"; }
die()  { printf '\n\033[1;31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "Run as your normal user, not root (it will sudo when needed)."
pgrep -x cqrlog >/dev/null && die "Close CQRLOG first, then re-run."

# ---- 0. which distro? ------------------------------------------------------
if   command -v apt-get >/dev/null; then PKG=apt
elif command -v pacman  >/dev/null; then PKG=pacman
elif command -v dnf     >/dev/null; then PKG=dnf
else die "Unsupported package manager. Install git, make, lazarus, fpc and the
       OpenSSL dev package by hand, then re-run this script."
fi

cat <<BANNER

  CQRLog Enhanced installer
  =========================
  Source will live in : $SRCDIR
  Program installs to : /usr/bin/cqrlog
  Your log/config     : ~/.config/cqrlog   (never touched by this script)

  This takes about five minutes, mostly compiling.

BANNER

# ---- 1. build tools --------------------------------------------------------
say "Step 1/5  Installing the build tools (needs your password)..."
case "$PKG" in
  apt)    sudo apt-get update -qq
          sudo apt-get install -y git make lazarus lcl lcl-gtk2 lcl-units \
                                  lcl-utils fpc fpc-source fp-units-rtl \
                                  fp-units-misc libssl-dev ;;
  pacman) sudo pacman -Sy --needed --noconfirm git make lazarus fpc openssl ;;
  dnf)    sudo dnf install -y git make lazarus fpc openssl-devel ;;
esac
command -v lazbuild >/dev/null || die "lazbuild still not found after installing Lazarus."

# ---- 2. source -------------------------------------------------------------
if [ -d "$SRCDIR/.git" ]; then
  say "Step 2/5  Updating the source in $SRCDIR..."
  git -C "$SRCDIR" pull --ff-only || warn "Could not fast-forward; building what is there."
else
  say "Step 2/5  Downloading the source to $SRCDIR..."
  [ -e "$SRCDIR" ] && die "$SRCDIR exists but is not a git clone. Move it aside and re-run."
  git clone --depth 1 "$REPO" "$SRCDIR"
fi
cd "$SRCDIR"

# ---- 3. compile ------------------------------------------------------------
say "Step 3/5  Compiling (this is the slow part, ~2-5 minutes)..."
if ! make cqrlog; then
  # Fresh Lazarus installs sometimes have no usable primary config path, which
  # shows up as: Invalid Lazarus directory "". Point lazbuild at it explicitly.
  warn "Default build failed — retrying with an explicit Lazarus directory..."
  LAZDIR=""
  # Debian/Ubuntu use a versioned subdir (/usr/lib/lazarus/2.2.6), Arch and
  # Fedora put it at the bare path. Test both, and require lcl/ to confirm.
  for d in /usr/lib/lazarus/default /usr/lib/lazarus /usr/lib/lazarus/* \
           /usr/share/lazarus /usr/share/lazarus/*; do
    [ -d "$d" ] && [ -e "$d/lcl" ] && { LAZDIR="$d"; break; }
  done
  [ -n "$LAZDIR" ] || die "Could not locate the Lazarus installation directory."
  info "using $LAZDIR"
  lazbuild --lazarusdir="$LAZDIR" --pcp="$HOME/.lazarus" --ws=gtk2 src/cqrlog.lpi
  strip src/cqrlog
  gzip -c tools/cqrlog.1 > tools/cqrlog.1.gz
fi
[ -x src/cqrlog ] || die "Build finished but src/cqrlog was not produced."

# ---- 4. install ------------------------------------------------------------
# 'make install' (not a bare copy of the binary) — it also installs
# /usr/share/cqrlog: country files, help pages, icons, the globe and the
# changelog. Without those you get a logger with no DXCC country data.
say "Step 4/5  Installing the program and its data files..."
sudo make install

# ---- 5. database -----------------------------------------------------------
say "Step 5/5  Setting up the database..."
bash "$SRCDIR/cqrlog-db-setup.sh"

cat <<'DONE'

  ============================================================
   Installed. Start CQRLOG from your applications menu
   (or type  cqrlog  in a terminal).

   On the first run, answer YES to
   "save data to a local machine".
  ============================================================

   To upgrade later, just run this installer again.

   73 de N8EM
DONE
