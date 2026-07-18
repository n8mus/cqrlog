# CQRLog Enhanced

Fork of CqrlogAlpha (itself a fork of CQRLog) — Lazarus/Free Pascal amateur radio
logging application, MySQL/MariaDB backend. See [README.md](README.md) for
user-facing feature notes; this file is for working on the source.

## Database engine detection (Enhanced 7)

`TdmData.GetMysqldPath` (`src/dData.pas`) searches for **`mariadbd` as well
as `mysqld`** — MariaDB 10.4+ renamed the daemon and modern distros drop the
`mysqld` symlink, which was the #1 "Can't connect to local MySQL server"
install failure. `cqrlog-db-setup.sh` (repo root) is the tester-facing
fixer: installs mariadb-server, symlinks `mysqld`→`mariadbd` (so even
upstream cqrlog works), adds the Debian/Ubuntu AppArmor exception for
`~/.config/cqrlog/database`, and a "database doctor" that moves aside a
corrupted datadir (guarded: a datadir with a `mysql/` dir or
`aria_log_control` is treated as healthy and never touched).

## Build

    lazbuild --ws=gtk2 --pcp=$HOME/.lazarus src/cqrlog.lpi

Run from the repo root. `--pcp=$HOME/.lazarus` points at the existing Lazarus
primary config path (has `LazarusDirectory`/`CompilerFilename` set) — without
it lazbuild fails with `Invalid Lazarus directory ""`. `make cqrlog` wraps the
same lazbuild call but defaults to a `/tmp` pcp that isn't configured; prefer
the direct lazbuild command above.

A successful build produces `src/cqrlog`. Ignore two benign linker warnings
(`crtbeginS.o`/`crtendS.o` not found) and a `world_borders.png not found`
pre-flight notice from lazbuild — both pre-exist and don't affect the build.

## Install (always keep a fallback)

The source tree here is separate from the installed binary (`/usr/bin/cqrlog`)
and the live database/config (`~/.config/cqrlog`). Always back up the current
binary before overwriting it:

    sudo -v && \
    sudo cp /usr/bin/cqrlog /usr/bin/cqrlog.bak.$(date +%Y%m%d%H%M) && \
    sudo cp src/cqrlog /usr/bin/cqrlog && \
    md5sum /usr/bin/cqrlog src/cqrlog

Whenever `src/changelog.html` changes, also deploy it — the running app
reads `changelog.html` from `dmData.ShareDir` (`/usr/share/cqrlog/`, a
relative `../share/cqrlog/` from the binary), a completely separate copy
from this repo that the binary-only install above never touches. Left
stale, `Help > Changelog` and the once-per-version auto-popup both show
old content, and — since the "seen" flag is stamped into the user's ini
the moment the version differs, independent of what actually got shown —
it looks like the changelog silently failed to update rather than served
the wrong file:

    sudo cp src/changelog.html /usr/share/cqrlog/changelog.html

## Git / releases

- Remote `origin` = `n8mus/cqrlog` on GitHub, default branch `master`, public.
- Version string lives in `src/uVersion.pas` (`cVersionBase`, format
  `Name_(N)_`). The in-app update nag (`TfrmNewQSO.CheckForAlphaVersion` in
  `src/fNewQSO.pas`) fetches `compiled/version.txt` from `master` via
  `raw.githubusercontent.com` and compares the `(N)` number — bump both
  together when cutting a release, or the nag either falsely fires or goes
  silent.
- `src/changelog.html` is shown automatically once per version bump (compared
  against a stored value in the user's ini) — add an entry there for
  user-facing changes.

## Architecture notes learned while working in this codebase

- **FPC visibility-section rule**: within one `private`/`public`/`published`
  block, all field declarations must precede all method declarations, or you
  get error 3251 ("Fields cannot appear after a method or property
  definition"). Keep new fields grouped with existing fields, new method
  decls grouped with existing method decls.
- **`.lfm` anchor chains**: components position via `AnchorSideTop.Control` /
  `Side = asrBottom` chains to a sibling, not the literal `Top` value (which
  is just a design-time snapshot). Before anchoring a new control to what
  looks like "the last item" in a column, verify nothing else already
  anchors there — `grep AnchorSideTop.Control` for the target name. TabOrder
  number does *not* indicate vertical position in the anchor chain.
- **`TColorMemo`** (`src/uColorMemo.pas`) is a single-column colored-text-line
  display used for DX cluster spot feeds — not a real multi-column grid.
- **DX cluster spot pipeline**: any spot source (Web/Telnet/POTA) formats a
  line as `"DX de SPOTTER: FREQ CALL COMMENT TIMEZ"` and calls
  `TfrmDXCluster.ShowSpot` (`src/fDXCluster.pas`) for DXCC/worked-status
  coloring, then `Synchronize`s under the `csTelnet` critical section to
  append via `TColorMemo.AddLine`. Click-to-tune reuses the same text format:
  `SpotDbClick` → `dmDXCluster.GetSplitSpot` → `frmNewQSO.NewQSOFromSpot`.
  New spot sources should follow this exact pattern rather than inventing a
  new UI path.
- **Visible QSO grid columns** are wired in *two* separate places that must
  both be updated together: `TdmUtils.LoadVisibleColumnsConfiguration`
  (`src/dUtils.pas`, feeds the New QSO recent-contacts grid) and
  `TfrmMain.ShowFields`/`ChangeVis` (`src/fMain.pas`, the main log grid).
  Both read the same `Columns` ini section but are independent code paths.
- **DB schema migrations**: `TdmData.UpgradeMainDatabase(old_version)` in
  `src/dData.pas`, gated by `cDB_MAIN_VER`. Check the *live* installed
  database's `db_version.nr` before picking a new version number — it may
  already be ahead of what's in this git history from an earlier untracked
  build.
- **Online-log upload engine** (since 5ace500): parallel — the main
  thread pre-renders per-service work lists (`dmLogUpload.BuildUploadWork`;
  ALL DB access stays on the main thread, the shared connection is not
  thread-safe), one HTTP-only `TUploadThread` per service, results
  marshaled back via `Synchronize`. `upload_status` rows are per-service
  bookmarks into `log_changes`; both `MarkAsUploaded` variants self-heal a
  missing service row (qrz.com was never seeded upstream) and the bulk
  mark is scoped by logname (upstream stomped all services' pointers).
  The ledger collapse runs only after a clean all-enabled-services round.
  QRZ deletes need the LOGID captured at insert time — deleting a QSO
  while its upload round is still in flight breaks that chain (known
  race; let rounds finish before deleting).
- **Auto-LoTW** (7655f9b): `AutoLotwQsoSaved` (fLoTWExport) is kicked
  from `UploadAllQSOOnline` on every save; quiet-period TTimer (120 s)
  batches unsigned QSOs, background thread runs the operator's tqsl
  template + `-u -a compliant -q` via `/bin/sh -c`, success (exit 0/8/9)
  marks `lotw_qsls='Y'` and refreshes the grid. Enable checkbox is
  created at RUNTIME in the LoTW export dialog (no .lfm edit). LoTW is
  not in the log_changes ledger. NOTE: LoTW's Activity page lists only
  PROCESSED files — a queued upload is invisible there for minutes-hours.
- **Auto-eQSL** (9f324cb): mirror of auto-LoTW in feQSLUpload
  (LoTW/eAutoUpload, quiet-period batch, POST to ImportADIF.cfm). CRITICAL
  invariant: QSL-status marking UPDATEs (lotw/eqsl marks, qrz_logid) must
  run with session flag `@cqr_qsl_mark=1` set — the cqrlog_main_bu trigger
  (INSERT..SELECT..WHERE @cqr_qsl_mark IS NULL) skips ledger-queueing
  while it's set. Without the flag one status batch re-queues every QSO
  as a full UPDATE for all services. The trigger fix lives in dData.lfm
  SOURCE because preferences saves re-run the trigger script and wipe
  DB-only fixes (this exact bug had been fixed live once and came back).
- **Confirmation auto-download** (Enhanced 9 LoTW, 10 eQSL): the *download*
  side of the same idea — a daily opt-in pull of LoTW/eQSL confirmations.
  One `TTimer` in fNewQSO (`tmrLoTWAuto`, created in
  `CheckForExternalTablesUpdate`) fires ~20 s after startup then hourly;
  `LoTWAutoCheck` also calls `eQSLAutoCheck`, each independently gated on
  its own `LoTWImp/AutoDownload` / `eQSLImp/AutoDownload` opt-in (default
  OFF), a per-calendar-day `AutoLastRun` stamp, and creds. The pull itself
  is `TfrmImportLoTWWeb.RunAutoDownload` / `TfrmeQSLDownload.RunAutoDownload`
  (headless: fetch the ADIF with stored creds — eQSL is two-step, request
  inbox link then fetch — then import via `TfrmImportProgress` with the new
  `Silent` flag suppressing the not-found prompts). Incremental window is a
  stored `AutoSince` watermark (first run = last 30 days, advanced to
  today−2 for overlap; already-'L'/'E' QSOs are skipped so overlap is
  free). Runs on the MAIN thread (brief modal flash), not a worker — DB
  access must stay on the main thread. The opt-in checkbox is created at
  RUNTIME in each download dialog (no .lfm edit, like the auto-upload
  enable). CRITICAL: the confirmation *import* (`ImportLoTWAdif` /
  `ImporteQSLAdif` in fImportProgress) marks `lotw_qslr='L'` /
  `eqsl_qsl_rcvd='E'` and MUST wrap those UPDATEs in `@cqr_qsl_mark=1`
  (same invariant as above) — upstream did not, so every confirmation
  re-queued its QSO for re-upload; the guard now brackets both mark loops
  (reset in the `finally`, survives the rollback) and fixes the manual
  download too. To bulk-add LoTW's "QSO not found" report
  (`~/errors_LoTW.adi`): it is cqrlog's error dump, not a clean import —
  strip the `CONTEST_ID=Qso_was_not_found_in_log!` tag and re-tag
  `QSL_RCVD` as `LOTW_QSL_RCVD`+`LOTW_QSLRDATE`, then File→Import→ADIF
  (`acImportADIF`, general import, which honors those and sets
  `lotw_qslr='L'`); the LoTW import only *marks* existing QSOs.
- **Console bridge extras** (since Enhanced 5): the UDP 2334 listener also
  accepts a populate-only message `CQRLOOKUP:CALL[;PARK:ref][;GRID:loc]`
  (`HandleConsoleLookup` in fNewQSO) — fills New QSO + callbook lookup, no
  save. A spot-supplied grid (POTA park) sets `SpotGrid`/`SpotGridCall`,
  which `SynCallBook` honors so the QRZ home locator can't overwrite it
  (Jon runs `UseCallBookData=1` = always-replace); cleared in `ClearAll`.
  SP/LP buttons beside `lblAzi` send one-shot `P az 0` to rotctld (ROT1
  host/port) via `SendRotorAzimuth` — no rotor window, no polling session.
- **Rotor is lazy** (since Enhanced 5): cqrlog no longer connects to
  rotctld at startup — `InicializeRot` is gated on `RotWanted`, set only
  when the rotor window opens (and cleared + rotor freed on close). Two
  500 ms pollers (cqrlog + SDR console) swamp the DCU-3's 4800 Bd serial
  and the daemon backlogs unboundedly — one polling client max.
- **POTA fields**: `pota_ref` (park *you* activated during that QSO) and
  `pota_hunted_ref` (park the *other station* was in) on `cqrlog_main`, also
  selected by the `view_cqrlog_main_by_qsodate*` views. ADIF uses the legacy
  `SIG`/`SIG_INFO`/`MY_SIG`/`MY_SIG_INFO` tags (not the newer `POTA_REF`
  tags) for compatibility with pota.app's real-world parser.
