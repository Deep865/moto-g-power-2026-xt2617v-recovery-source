# Source status — Moto G Power 2026 (`XT2617V`, Walmart / Straight Talk)

Last updated: 2026-11-22.

## Supported: three working recoveries

All three build from this tree on the **12.1** core and were re-tested on the device
on 2026-11-22 with an encrypted `/data` and PIN `1234`:

| Recovery | Script | Self-test | SHA-256 |
|---|---|---:|---|
| OrangeFox R12.0 | `scripts/91-build-ofox12-recovery.sh` | **17/17** + sideload | `9cd70969…24a0` |
| TWRP 3.7.1-12 | `scripts/92-build-twrp12.sh` | **17/17** | `0a241558…c5d7` |
| PBRP 4.x | `scripts/93-build-pbrp12.sh` | **17/17** | `c899f61e…77cb` |

Verified on all three: UI, FT8725 touch (`fts_ts` on `/dev/input/event2`), FBE
`/data` decrypt, `/sdcard` read/write, gatekeeper symlink, AW862x haptics, MTP/ADB
and six 1080×2388 panel modules. OrangeFox also completed an ADB sideload.

Build one at a time with the per-recovery sheets in [`recoveries/`](recoveries/) or
all three with [`BUILD-ALL.md`](BUILD-ALL.md).

## What is in the tree

- One device tree (`device/motorola/vegas26`) used by all three manifests.
- OrangeFox 12.1 core `8cd9df2b4`, which includes:
  - skip the data-size scan before decrypt;
  - fall back between `/dev/block/bootdevice/by-name` and `/dev/block/by-name`;
  - thermal-sensor unsigned-wrap fix;
  - bzip2 available in recovery;
  - configurable vibration defaults;
  - Reboot Recovery after actions;
  - optional double-tap-to-wake (`FOX_NO_BLANK_DT2W`).
- LF text, real gatekeeper symlinks, minimal fstab, haptic load order, sideload
  `adbd` handling and no UPX.
- Stock FT8725 touch module from `vendor_dlkm`; the bundled G Play module fails
  with `ENODEV` on this board.

## Tested binaries and full phone guide

<https://github.com/Deep865/moto-g-power-2026-xt2617v-walmart-unlock-degoogle-guide>

The docs repo contains the complete path for a Walmart / Straight Talk unit:
Test DPC SIM-screen bypass, temporary root, LK patch and bootloader unlock, Magisk,
LineageOS 23.2 microG GSI, recovery flash, modem unlock and revert.

## Experimental: 14.1 / 16.0

Not supported. Both OrangeFox branches build but do not reach a usable recovery UI
on this Android 16 vendor; their full images can also exceed the ~55.5 MB
`vendor_boot` content limit. TWRP 14.1 has the same userspace blocker.

- Historical notes: [`experimental/README.md`](experimental/README.md) and
  [`experimental/BUILD-14.1-16.0.md`](experimental/BUILD-14.1-16.0.md)
- Old scripts: `scripts/experimental/` (kept for reference; not turnkey)
- What we want to bring into 12.1 next:
  [`experimental/BACKPORT-ROADMAP.md`](experimental/BACKPORT-ROADMAP.md)

## Modem

The modem/network lock lives in `md1img`, not the bootloader. `vegas-freedom` was
audited and an experimental patched image was flashed to `md1img_a` only; there was
no SIM available, so **network unlock is not verified**. Never publish
`md1img`/IMEI/`nvram`/`nvdata`/`seccfg`/`persist`/`frp`/`protect*` dumps. Details:
docs repo `docs/07-modem-unlock.md`.

## Cautions

- Flash only `vendor_boot_a`; keep the stock image for revert.
- Never relock the bootloader with modified `lk`/`init_boot`.
- Do not flash another device's recovery/ROM.
- Build on Linux/WSL2; Windows CRLF and flattened symlinks break the boot.
