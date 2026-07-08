# CQRLog Enhanced

Fork of CqrlogAlpha (itself a fork of CQRLog) — Lazarus/Free Pascal amateur radio
logging application, MySQL/MariaDB backend. See [README.md](README.md) for
user-facing feature notes; this file is for working on the source.

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
- **POTA fields**: `pota_ref` (park *you* activated during that QSO) and
  `pota_hunted_ref` (park the *other station* was in) on `cqrlog_main`, also
  selected by the `view_cqrlog_main_by_qsodate*` views. ADIF uses the legacy
  `SIG`/`SIG_INFO`/`MY_SIG`/`MY_SIG_INFO` tags (not the newer `POTA_REF`
  tags) for compatibility with pota.app's real-world parser.
