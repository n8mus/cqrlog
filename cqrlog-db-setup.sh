#!/usr/bin/env bash
# CQRLOG database fixer / setup for Linux — kills the "Can't connect to
# local MySQL server through socket" wall that stops so many installs.
#
# It does the four things the forum threads are full of:
#   1. installs MariaDB server + client (and cqrlog if you want)
#   2. makes the modern 'mariadbd' binary findable under the old 'mysqld'
#      name that cqrlog looks for (distros dropped that symlink)
#   3. adds the AppArmor exception so the DB can use ~/.config/cqrlog
#      (Debian/Ubuntu only)
#   4. "database doctor": clears a corrupted/half-written local DB dir left
#      by an unclean shutdown, so cqrlog can rebuild it cleanly
#
# Safe to re-run. Works alongside the CQRLOG Enhanced fork or upstream cqrlog.
set -euo pipefail

DBDIR="$HOME/.config/cqrlog/database"
say()  { printf '\n\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!  %s\033[0m\n' "$1"; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }
[ "$(id -u)" -ne 0 ] || die "Run as your normal user (it will sudo when needed)."
pgrep -x cqrlog >/dev/null && die "Close CQRLOG first, then re-run (the database doctor must not touch a live DB)."

# ---- 1. install MariaDB (+ optionally cqrlog) -----------------------------
if   command -v apt-get >/dev/null; then PKG=apt
elif command -v pacman  >/dev/null; then PKG=pacman
elif command -v dnf     >/dev/null; then PKG=dnf
else die "Unsupported package manager — install mariadb-server + client by hand, then re-run."
fi
say "Installing MariaDB server + client (needs sudo)..."
case "$PKG" in
  apt)    sudo apt-get update -qq
          sudo apt-get install -y mariadb-server mariadb-client ;;
  pacman) sudo pacman -Sy --needed --noconfirm mariadb mariadb-clients ;;
  dnf)    sudo dnf install -y mariadb-server mariadb ;;
esac

# ---- 2. mysqld -> mariadbd compatibility ----------------------------------
# cqrlog looks for a binary named 'mysqld'; modern MariaDB only ships
# 'mariadbd'. Give cqrlog what it expects. (The Enhanced fork also finds
# mariadbd directly, but this makes even upstream cqrlog work.)
say "Ensuring cqrlog can find the database server binary..."
MARIADBD="$(command -v mariadbd || true)"
[ -n "$MARIADBD" ] || MARIADBD="$(ls /usr/sbin/mariadbd /usr/bin/mariadbd 2>/dev/null | head -1 || true)"
[ -n "$MARIADBD" ] || die "mariadbd not found even after install — check the MariaDB package."
if command -v mysqld >/dev/null || [ -e /usr/sbin/mysqld ] || [ -e /usr/bin/mysqld ]; then
  echo "    'mysqld' already resolves — good."
else
  sudo ln -sf "$MARIADBD" /usr/sbin/mysqld
  sudo ln -sf "$MARIADBD" /usr/bin/mysqld
  echo "    linked mysqld -> $MARIADBD"
fi

# ---- 3. AppArmor exception (Debian/Ubuntu) --------------------------------
if [ "$PKG" = apt ] && command -v aa-status >/dev/null 2>&1; then
  say "Adding the AppArmor exception so the DB can use ~/.config/cqrlog..."
  for prof in usr.sbin.mariadbd usr.sbin.mysqld; do
    if [ -e "/etc/apparmor.d/$prof" ]; then
      LOCAL="/etc/apparmor.d/local/$prof"
      sudo mkdir -p /etc/apparmor.d/local
      if ! sudo grep -q "cqrlog/database" "$LOCAL" 2>/dev/null; then
        printf '  @{HOME}/.config/cqrlog/database/ r,\n  @{HOME}/.config/cqrlog/database/** rwk,\n' \
          | sudo tee -a "$LOCAL" >/dev/null
      fi
      sudo apparmor_parser -r "/etc/apparmor.d/$prof" 2>/dev/null || true
      echo "    patched $prof"
    fi
  done
else
  echo "    (no AppArmor — nothing to do on this distro)"
fi

# ---- 4. database doctor: clear a corrupted local DB dir --------------------
if [ -d "$DBDIR" ]; then
  # Stop any stray mysqld/mariadbd first so we don't fight a live server.
  pkill -u "$USER" -f "datadir=$DBDIR" 2>/dev/null || true
  sleep 1
  BROKEN=0
  # Orphaned InnoDB redo logs or a stale lock from an unclean exit, or the
  # system tables never got created — all show as "won't start" in cqrlog.
  [ -e "$DBDIR/aria_log_control" ] || [ -d "$DBDIR/mysql" ] || BROKEN=1
  if [ "$BROKEN" = 1 ]; then
    warn "The local database folder looks incomplete/corrupted."
    BK="$DBDIR.broken.$(date +%Y%m%d%H%M%S)"
    mv "$DBDIR" "$BK"
    warn "Moved it aside to: $BK"
    echo "    cqrlog will build a fresh local database on next launch."
    echo "    (Your QSOs live in the database; if that folder held real data,"
    echo "     don't panic — it's backed up above. Ask before deleting it.)"
  else
    echo "    local database folder looks OK — leaving it alone."
    rm -f "$DBDIR"/*.lock "$DBDIR"/*.pid 2>/dev/null || true
  fi
else
  echo "    no local database yet — cqrlog will create one on first launch."
fi

say "Done. Start CQRLOG and answer YES to 'save data to a local machine'."
echo  "    If it still cannot connect, run 'cqrlog --debug=1' from a terminal"
echo  "    and send the output — but the four usual causes are now handled."
