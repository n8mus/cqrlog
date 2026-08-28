# CQRLog Enhanced

An enhanced fork of [CQRLOG](https://www.cqrlog.com/) for Linux hams —
**POTA built in, hands-free online-log uploads *and* confirmation
downloads, clearer DX-cluster colors, modern-MariaDB fixes**, and a
bridge for its companion
[Ten-Tec SDR console](https://github.com/n8mus/orion3-sdr-console).

CQRLOG is by Petr, OK2CQR, with alpha development continued by Saku,
OH1KH ([CqrlogAlpha](https://github.com/OK2CQR/CqrlogAlpha)). This fork
is built on Alpha 141 and stands on their work — thank you both. All
original license terms apply (GPL; see COPYING).

**Fair warning, in my own words:** I am not a programmer — I'm a ham
(N8EM) who built the features I wanted for my own station, with the
help of Anthropic's Claude. It's daily-driven here and working well,
but this is alpha-based software: **back up everything** before you
try it, especially your database.

## Install

There is no prebuilt download — you compile it, which takes about five
minutes and one copy-paste per step. Do all six steps, in order.

### 1. Install the build tools

**Debian / Ubuntu / Linux Mint:**

```
sudo apt update
sudo apt install -y git make lazarus lcl lcl-gtk2 lcl-units lcl-utils \
                    fpc fpc-source fp-units-rtl fp-units-misc libssl-dev
```

**Arch:**

```
sudo pacman -S --needed git make lazarus fpc openssl
```

Fedora is the same idea with `dnf install git make lazarus fpc
openssl-devel`.

### 2. Get the source

```
git clone https://github.com/n8mus/cqrlog.git
cd cqrlog
```

### 3. Build it

```
make cqrlog
```

If that fails with `Invalid Lazarus directory ""`, your Lazarus config
has never been initialised — open the Lazarus IDE once, let it set
itself up, close it, and run `make cqrlog` again.

### 4. Install it

```
sudo make install
```

**Use `make install`, not just a copy of the binary.** CQRLOG needs its
data directory (`/usr/share/cqrlog`) for country files, help pages,
icons, the grey-line globe and the changelog. Copying only the
executable gives you a program with no DXCC country data and no
application-menu entry.

### 5. Set up the database

The #1 reason CQRLOG won't start on a fresh Linux install is the local
database: modern **MariaDB** renamed its server from `mysqld` to `mariadbd`
and most distros dropped the old name, so CQRLOG can't find the daemon and
throws *"Can't connect to local MySQL server through socket."* On
Debian/Ubuntu, AppArmor also blocks the database folder.

This fork already searches for `mariadbd` directly, and this one-liner
fixes the rest for you — installs MariaDB, makes the server findable,
adds the AppArmor exception, and repairs a corrupted database folder:

```
bash <(curl -fsSL https://raw.githubusercontent.com/n8mus/cqrlog/master/cqrlog-db-setup.sh)
```

Run it with CQRLOG closed. It sets up the *database only* — it does not
install CQRLOG, so don't skip steps 1–4. Safe to re-run; it won't touch a
healthy database. See [`cqrlog-db-setup.sh`](cqrlog-db-setup.sh) for
exactly what it does.

### 6. Start it

Launch CQRLOG from your application menu and answer **YES** to "save data
to a local machine."

### Upgrading later

```
cd cqrlog
git pull
make cqrlog && sudo make install
```

Your log lives in `~/.config/cqrlog`, untouched by an upgrade — but back
it up anyway before you do this.

## Optional extras

- **Rig control**: `hamlib` / `libhamlib-utils` (provides `rigctld`).
- **LoTW**: TrustedQSL (`trustedqsl` on Debian/Ubuntu, AUR on Arch) —
  required for the automatic LoTW signing and upload.
- **Grey-line map**: `xplanet`.

## What "Enhanced" adds over stock CQRLOG

### POTA — Parks on the Air, built in
- POTA on the New QSO window: log the park **you** activated and the
  park the **other station** was in (both stored in the log).
- Live **POTA spot feed** inside the DX Cluster window.
- POTA spots colored by **park-worked status** — not by DXCC country —
  so an all-new park stands out at a glance.
- **N-fer support**: a multi-park activation credits every park.
- ADIF done the way the POTA world actually works: exports
  `SIG`/`SIG_INFO` tags (what pota.app parses), imports
  `POTA_REF`/`MY_POTA_REF` as a fallback.

### Online logs, hands-free
- **QRZ.com logbook**: real-time upload of every saved QSO, auto-delete
  when you delete, LOGID tracked so deletes are reliable.
- **LoTW**: every logged QSO is signed and uploaded automatically in
  the background (batched). The manual sign/upload button no longer
  freezes the GUI.
- **eQSL**: the same automatic-upload treatment.
- **Confirmations come back by themselves**: a daily background pull
  downloads your LoTW and eQSL confirmations and marks the QSOs.
- Uploads run in **parallel** — one worker per service, so one slow
  service never holds up the rest.

### DX Cluster
- Color-coding overhaul: clearer, more consistent worked-before status
  colors on cluster spots.

### Quality of life
- Works with **modern MariaDB** out of the box (finds `mariadbd`, not
  just `mysqld`).
- **Clear all fields** button (Ctrl+F2) on New QSO.
- The update check is fork-aware — no more nagging about upstream
  versions.

### SDR-console bridge
Companion to my
[Ten-Tec SDR console](https://github.com/n8mus/orion3-sdr-console)
for the Ten-Tec Orion / Omni VII: an always-on UDP bridge lets the
console log a QSO into CQRLOG with one click, click a spot on the
panadapter to fill New QSO (with park-grid-accurate rotor azimuth),
and adds SP/LP rotor buttons to New QSO. Completely inert if you don't
run the console.

## Database changes for the QRZ feature (existing databases only)

A fresh database gets everything automatically on first run, and the
POTA and other Enhanced columns are added automatically by the normal
database upgrade. The two QRZ columns are the exception — if you bring
an **existing** CQRLOG database, run these once while CQRLOG is running:

    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "ALTER TABLE cqrlog_main ADD COLUMN qrz_logid varchar(20) DEFAULT '';"
    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "ALTER TABLE log_changes ADD COLUMN qrz_logid varchar(20) NULL;"
    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "INSERT INTO upload_status (logname, id_log_changes) VALUES ('qrz.com', 1);"

Then recreate the delete trigger:

    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "DROP TRIGGER IF EXISTS cqrlog_main_bd;"
    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "CREATE TRIGGER cqrlog_main_bd BEFORE DELETE ON cqrlog_main FOR EACH ROW insert into log_changes(id_cqrlog_main,cmd,old_qsodate,old_time_on,old_callsign,old_mode,old_band,old_freq,qrz_logid) values (OLD.id_cqrlog_main,'DELETE',OLD.qsodate,OLD.time_on,OLD.callsign,OLD.mode,OLD.band,OLD.freq,OLD.qrz_logid);"

## Configuration (QRZ upload)

1. Open CQRLOG -> File -> Preferences -> Online Log
2. Scroll to the QRZ.com Logbook section
3. Enter your callsign and QRZ API key
4. Check Enable QRZ.com logbook upload
5. Check Upload QSO data immediately for real-time upload
6. Check Close upload window after successful upload
7. Click OK

Your QRZ API key is found at qrz.com -> Logbook -> Settings -> API Key.
LoTW and eQSL use the standard CQRLOG preferences; the automatic
upload and daily confirmation download switch on with them.

## Requirements

- Linux (developed and daily-driven on Arch; earlier versions also
  installed clean on Linux Mint 22.1)
- Free Pascal Compiler 3.2.2+ and Lazarus with `lazbuild`
- MariaDB/MySQL — handled for you by step 5 of the install
- A QRZ.com account with logbook enabled — only for the QRZ upload
  feature

The lnet TCP/UDP library is bundled in-tree, so the build works out of
the box (no extra Lazarus packages to hunt down).

## Base project

- [CQRLOG](https://www.cqrlog.com/) by Petr, OK2CQR
- [CqrlogAlpha](https://github.com/OK2CQR/CqrlogAlpha) — alpha line by
  Saku, OH1KH; this fork is based on Alpha 141 (Build 1, 2026-03-17)

All original license terms apply. See COPYING for details.

73 de N8EM
