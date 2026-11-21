# Source status — vegas26

Last updated: 2026-11-21.

## TWRP 14.1 (this tree)

- Manifest: `minimal-manifest-twrp/platform_manifest_twrp_aosp`, branch `twrp-14.1`.
- Lunch: `twrp_vegas26-ap2a-eng`.
- Target: `vendorbootimage`.
- Result: builds; the image passes every header/DTB/fragment check and flashes.
- Boot result: **does not reach a usable UI** on this Android 16 vendor. Observed a
  glitch/reboot or a “hello moto” hang. pstore shows the TWRP userspace failing to create
  the MTK block devices (`boot_a`, `super`, `metadata`, `vbmeta_a`, `vbmeta_system_a`).
- A hybrid (stock A16 vendor ramdisk + TWRP 14.1 recovery binary/libs) also hangs at the
  logo. Packaging/DTB/header are proven; the blocker is the 14.1 userspace.

A14 fixes are in `scripts/10-build-14.1.sh` / `scripts/11-rebuild.sh` and are summarized
in `BUILD.md`.

## OrangeFox 14.1 (known-good binary)

The recovery that actually boots on this unit is an OrangeFox 14.1-based image from the
XDA thread, rebuilt with the **phone’s own `vendor_dlkm` Focaltech FT8725 module**.

- Base: `vegas_ofox.img` (OrangeFox R12.0 unofficial; DTB `183530` /
  `50cf2684…`, 1080×2388 panel modules).
- Touch: stock module `focaltech_0flash_mmi_v3.ko` (234,560 bytes, MD5 `c0af43…`)
  replaces the image’s 412,600-byte variant (MD5 `85263c…`) that fails with `ENODEV`.
- Result: `vegas_ofox_fixed.img`, SHA-256 `ddcc5967…`.
- Working: touch, `/data` decryption, backup/restore, MTP, ADB.
- **Tested with the LineageOS GSI installed**: OrangeFox still boots, touch works
  (`fts_ts` / event2), and `/data` decrypts (dm-7 mounted, `/sdcard` accessible).

Reproduction: docs repo `REPRODUCE.md` + `scripts/60-repack-ofox-touch.sh`.

## GSI (tested)

LineageOS 23.2 microG (Android 16) is installed on `system_a` and boots:

- `ro.build.version.release=16`
- `ro.lineage.version=23.2-20261118-UNOFFICIAL-GSI`
- `/data` encrypted (`ro.crypto.state=encrypted`)
- no SIM (`gsm.sim.state=ABSENT,NOT_READY`) — used as a Wi-Fi backup phone
- OrangeFox 14.1 recovery decrypts its `/data` and touch works

Flashing the GSI does **not** SIM/network unlock the modem. Bootloader unlock and SIM
lock are independent; the lock lives in `md1img`.

## OrangeFox 16.0 (in progress)

`fox_16.0` is an Android 16 OrangeFox branch and is the intended source-built recovery
for this A16 vendor.

- `orangefox_sync.sh --branch 16.0` completed successfully.
- Tree copied to `device/motorola/vegas26`.
- Stock 1080×2388 DSI panel modules added; stock FT8725 module replaces the wrong one in
  all three module paths.
- `lunch omni_vegas26-bp2a-eng` works (Android 16, `BP2A`).
- Build in progress: `mka vendorbootimage -j16`.
- `vendorsetup.sh` obsolete `add_lunch_combo` lines removed (they return non-zero in the
  A16 envsetup and abort `set -e` scripts).

Goal: a from-source image that boots with the same DTB, panel modules and stock FT8725
module as the known-good 14.1 binary.

## TWRP-branded variant

After the OrangeFox 16.0 source build boots, a TWRP-branded variant is mostly theme/UI
and branding on the same recovery core. Do that later.
