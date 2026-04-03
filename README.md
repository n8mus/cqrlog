# CQRLOG — N8EM Fork (Alpha 140 + QRZ Logbook Upload)
Please do not use this version. It is under development and has known bugs
On this fork I am working on changes to the dxcluster window to mimic the 
Alert features similar to those found in other software. 
I added columns in the dxcluster for country band and mode with colored checks or X's
This makes for an easy visual as to if a new country or new band for a country or
New mode for a country. It also scans the log and returns for worked but unconfirmed. 
That is also for all 3 outputs country band and mode. 
Known bug is ADIF imports are not working now. More work to be done. 
Current cluster puts colors for the above I wanted a better visual. 
This is a fork of [CQRLOG](https://www.cqrlog.com/) Alpha 140, based on the
[cqrlog-xd](https://github.com/d3cker/cqrlog-xd) development branch, with the
following additions:

## What's New

### QRZ.com Logbook Auto-Upload
Real-time QSO upload to your QRZ.com logbook on every new QSO entry.

- Supports INSERT and DELETE operations
- Stores your QRZ API key and callsign in CQRLOG preferences
- Upload status shown in the log upload status window with color coding
- Duplicate QSO handling — gracefully skips already-uploaded QSOs
- Uses the QRZ logbook REST API: https://logbook.qrz.com/api

### LoTW Auto-Upload via tqsl
Automatic Logbook of the World upload triggered after each QSO session.

- Calls tqsl automatically to sign and upload pending QSOs
- Marks uploaded QSOs in the database to avoid re-uploading
- Configurable station location via CQRLOG preferences

## Requirements

- Linux (tested on Linux Mint 22.1 / Ubuntu-based)
- Free Pascal Compiler 3.2.2+
- Lazarus IDE with lazbuild
- PostgreSQL (standard CQRLOG requirement)
- A QRZ.com account with logbook enabled
- Your QRZ API key (found at qrz.com → Logbook → Settings)
- tqsl installed at /usr/bin/tqsl (for LoTW upload only)

## Building from Source

    git clone https://github.com/n8mus/cqrlog.git
    cd cqrlog/src
    lazbuild cqrlog.lpi
    sudo cp cqrlog /usr/bin/cqrlog

## Configuration

### QRZ Logbook Upload
1. Open CQRLOG → File → Preferences → Online Log
2. Find the QRZ.com section
3. Enter your callsign and QRZ API key
4. Check Enable QRZ upload
5. Optionally check Upload online for real-time upload on each QSO
6. Click OK

Your QRZ API key can be found by logging into qrz.com and navigating to
Logbook → Settings → API Key.

### LoTW Upload
1. Open CQRLOG → File → Preferences → LoTW/eQSL
2. Enable LoTW upload and set your station location
3. Ensure tqsl is installed and your certificate is configured

## Status

| Feature | Status |
|---|---|
| HamQTH real-time upload | Working |
| HRDLog real-time upload | Working |
| QRZ.com logbook upload | Added in this fork |
| LoTW upload via tqsl | Added in this fork |
| QRZ callbook lookup | Working |
| Club Log upload | Requires App Password setup |

## Base Project

- [CQRLOG](https://www.cqrlog.com/) by OK2CQR
- [cqrlog-xd](https://github.com/d3cker/cqrlog-xd) Alpha 140 branch by d3cker

All original license terms apply. See COPYING for details.

## Tested On

- Linux Mint 22.1 (x86_64)
- CQRLOG Alpha 140, Build 1, Date 2026-01-27
- Free Pascal Compiler 3.2.2

73 de N8EM
