# CQRLOG — N8EM Fork (Alpha 141 + QRZ Logbook Upload)

This is a fork of [CQRLOG](https://www.cqrlog.com/) Alpha 141, with full
QRZ.com logbook upload support added.

## What's New

### QRZ.com Logbook Auto-Upload
- Real-time QSO upload to QRZ.com logbook on every new QSO entry
- Auto-delete from QRZ when QSO is deleted in CQRLOG
- LOGID tracking — saves QRZ LOGID to database for reliable deletes
- QRZ.com entry in Online Log menu with Upload and Mark All options
- QRZ.com section in Preferences Online Log tab
- Status window closes automatically after successful upload
- Uses QRZ logbook REST API: https://logbook.qrz.com/api

## Database Changes Required
Two columns are added automatically on first run if using a fresh database.
For existing databases, run these once while CQRLOG is running:

    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "ALTER TABLE cqrlog_main ADD COLUMN qrz_logid varchar(20) DEFAULT '';"
    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "ALTER TABLE log_changes ADD COLUMN qrz_logid varchar(20) NULL;"
    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "INSERT INTO upload_status (logname, id_log_changes) VALUES ('qrz.com', 1);"

Then recreate the delete trigger:

    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "DROP TRIGGER IF EXISTS cqrlog_main_bd;"
    mysql -u cqrlog -S ~/.config/cqrlog/database/sock cqrlog001 -e "CREATE TRIGGER cqrlog_main_bd BEFORE DELETE ON cqrlog_main FOR EACH ROW insert into log_changes(id_cqrlog_main,cmd,old_qsodate,old_time_on,old_callsign,old_mode,old_band,old_freq,qrz_logid) values (OLD.id_cqrlog_main,'DELETE',OLD.qsodate,OLD.time_on,OLD.callsign,OLD.mode,OLD.band,OLD.freq,OLD.qrz_logid);"

## Building from Source

    git clone https://github.com/n8mus/cqrlog.git
    cd cqrlog/src
    lazbuild cqrlog.lpi
    sudo cp cqrlog /usr/bin/cqrlog

## Configuration

1. Open CQRLOG -> File -> Preferences -> Online Log
2. Scroll to the QRZ.com Logbook section
3. Enter your callsign and QRZ API key
4. Check Enable QRZ.com logbook upload
5. Check Upload QSO data immediately for real-time upload
6. Check Close upload window after successful upload
7. Click OK

Your QRZ API key is found at qrz.com -> Logbook -> Settings -> API Key.

## Requirements

- Linux (tested on Arch Linux 6.19 and Linux Mint 22.1)
- Free Pascal Compiler 3.2.2+
- Lazarus IDE with lazbuild
- MariaDB/MySQL (standard CQRLOG requirement)
- A QRZ.com account with logbook enabled

## Base Project

- [CQRLOG](https://www.cqrlog.com/) by OK2CQR
- [CqrlogAlpha](https://github.com/OK2CQR/CqrlogAlpha) Alpha 141

All original license terms apply. See COPYING for details.

## Tested On

- Arch Linux 6.19 (x86_64)
- Linux Mint 22.1 (x86_64)
- CQRLOG Alpha 141, Build 1, Date 2026-03-17
- Free Pascal Compiler 3.2.2

73 de N8EM
