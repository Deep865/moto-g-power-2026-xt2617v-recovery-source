# Build notes

The supported build guide is [`BUILD-ALL.md`](BUILD-ALL.md). It covers the three
working recoveries only:

- OrangeFox R12.0 — `scripts/91-build-ofox12-recovery.sh`
- TWRP 3.7.1-12 — `scripts/92-build-twrp12.sh`
- PBRP 4.x — `scripts/93-build-pbrp12.sh`

Per-recovery sheets are in [`recoveries/`](recoveries/), and the supported status is
in [`STATUS.md`](STATUS.md).

The historical TWRP 14.1 / OrangeFox 14.1 / OrangeFox 16.0 build notes moved to
[`experimental/BUILD-14.1-16.0.md`](experimental/BUILD-14.1-16.0.md). Those images do
not reach a usable recovery UI on this phone and are not published.

For what we want to bring back into 12.1, see
[`experimental/BACKPORT-ROADMAP.md`](experimental/BACKPORT-ROADMAP.md).
