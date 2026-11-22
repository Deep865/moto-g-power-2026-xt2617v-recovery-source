# Source status — vegas26

Last updated: 2026-11-22.

## OrangeFox 12.1 source (working, 2026-11-22)

The working XDA R12.0 image is now reproducible from this tree.

- Branch `fox_12.1`; `bootable/recovery` pinned to `3fc9e73f` (2026-08-21), the
  codebase recorded in the working image.
- Build: `scripts/90-build-ofox12-source.sh` with `FOX_SKIP_UPX=1` and
  `FOX_EXTREME_SIZE_REDUCTION=0`.
- Fixes: no UPX; all device-tree text files LF (a CRLF `prepdecrypt.sh` shebang
  breaks init); the two gatekeeper HAL aliases are symlinks, not flattened text;
  minimal working `recovery.fstab`.
- Verified on-device: UI, touch (`ft8725`), FBE `/data` decrypt, backup.
- Flashed image SHA-256 `88510c28…` (a fresh build may differ only by build ID).

## Three working recoveries (2026-11-22)

All on the 12.1 core, same device tree, same fixes (LF text, gatekeeper symlinks,
minimal fstab, no UPX, haptic order, sideload adbd stop):

- **OrangeFox R12.0** — `scripts/91-build-ofox12-recovery.sh`
  (+ two 14.1 backports: skip data-size scan before decrypt; `/dev/block/by-name`
  fallbacks). Sideload verified.
- **TWRP 3.7.1-12** — `scripts/92-build-twrp12.sh`.
- **PBRP 4.x** — `scripts/93-build-pbrp12.sh`.

14.1 and 16.0 bootloop on this A16 vendor and their full images exceed the ~55.5 MB
vendor_boot limit; do not offer them. Tests: 17/17 self-checks on all three
(UI, touch, FBE decrypt, backups, haptics, MTP/ADB).

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

## OrangeFox R12.0 (known-good binary)

The recovery that actually boots on this unit is an **OrangeFox R12.0** image from the
XDA thread, rebuilt with the **phone’s own `vendor_dlkm` Focaltech FT8725 module**. The
older “14.1-based” label was wrong; `REPRODUCE.md` and the R12.0 base are correct. The
TWRP 14.1 source and the OrangeFox 14.1/16.0 source builds are newer controls, not the
working daily recovery.

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

## OrangeFox 16.0 (experimental, not a working recovery)

`fox_16.0` is an Android 16 OrangeFox branch. The build compiles and verifies, but the
result is not a working recovery yet.

- `orangefox_sync.sh --branch 16.0` completed successfully.
- `lunch omni_vegas26-bp2a-eng`; build fixes: 4K/16K prebuilt page size, nano race,
  `vendorsetup.sh`.
- Built image `vendor_boot_ofox16.img`, SHA-256 `55c8175c…`; header/DTB/fragments PASS.
- **16.0 platform + 16.0 recovery** (and the slim recovery): logo → fastboot; no kernel
  log. The 16.0-built platform is the leading suspect.
- **R12.0 platform + 16.0 recovery**: loads; Android boots; the 16.0 recovery only draws
  the OrangeFox splash, never the menu. This is a userspace/theme failure.
- The slim recovery removed the Chinese theme font; the font-kept test was invalid because
  it also removed three panel modules (no splash, bootloop).
- **Full 16.0 recovery on the R12.0 platform** is 57.45 MB and hits the bootloader size
  limit (logo → fastboot). The size limit is between 55.57 MB (working R12.0) and
  57.45 MB.
- The old pstore panic is the TWRP 14.1 panic (initrd 54,896K), not a 16.0 log.

Full details/hashes: docs repo `docs/05-ofox16.md`.

## OrangeFox 14.1 source control

`fox_14.1` sync completed after retrying past an AOSP Gitiles HTTP 429 quota. The build
uses the A14 TWRP device tree. This is a newer control, not the exact working image; the
working image is R12.0. The true source control is the 12.1/R12.0 branch.

## SIM / modem

`vegas-freedom` offline check/build on the stock `md1img_a` passed its audit for this
`-4-3` unit, but **nothing was flashed**. Only `md1img_a` is ever flashed; never
`md1img_b`/`lk`/`preloader`/`seccfg`/`gpt`/`nvram`/`nvdata`/`protect*`. Verification
needs a non-Tracfone SIM. See docs `docs/07-modem-unlock.md` and `docs/06-sim-setup.md`.

## TWRP-branded variant

After the OrangeFox 16.0 source build boots, a TWRP-branded variant is mostly theme/UI
and branding on the same recovery core. Do that later.
