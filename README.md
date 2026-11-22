# vegas26 recovery source — Moto G Power 2026 (`XT2617V`)

Device tree, build scripts and status for recovery work on the MediaTek MT6835
**moto g power - 2026** (`XT2617V`, Android codename `vegas26`, bootloader `vegas`).

This is a research tree. Read `STATUS.md` before assuming any image is usable.

## Status at a glance

| Target | State |
|---|---|
| TWRP 14.1 from the minimal manifest + this tree | builds, verifies, flashes; **userspace does not reach UI** on the A16 vendor |
| **OrangeFox R12.0 (12.1 branch) known-good binary** | **works**: touch, `/data` decryption, backup/restore, MTP, ADB |
| OrangeFox 14.1 source (`fox_14.1`) | builds; **black screen / bootloop**; recovery userspace not usable |
| OrangeFox 16.0 source (`fox_16.0`) | builds; 16.0 platform fails at the bootloader; recovery splash/no menu — experimental |
| **OrangeFox 12.1/R12.0 source (`fox_12.1`)** | **works** (source-built 2026-11-22): touch, `/data` decrypt, backup — `scripts/90-build-ofox12-source.sh` |
| TWRP-branded variant | later; TWRP 14.1 has its own userspace blocker, 16.0 is closer |

The working binary recipe, hashes and full notes live in
**https://github.com/Deep865/vegas26-recovery** (docs repo).

## Device

| | |
|---|---|
| Model | moto g power - 2026 / `XT2617V` |
| Codename | `vegas26` (bootloader product `vegas`) |
| SoC | MediaTek MT6835 (Dimensity 6300) |
| Display | 1080 × 2388, 120 Hz, TXD FT8725 panel, Focaltech in-cell touch |
| Firmware | `W1WEOS36.48-22-3-3-4-3`, Android 16, patch 2026-06-01 |
| Kernel | 5.15.189-android13-8 |
| Recovery | vendor_boot (`platform`/recovery fragments; no recovery partition) |

## Quick start (TWRP 14.1)

```bash
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-14.1
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
cp -r device-tree device/motorola/vegas26   # or clone this repo there

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_vegas26-ap2a-eng
mka vendorbootimage -j16
```

The A14 fixes are automated in `scripts/10-build-14.1.sh` / `scripts/11-rebuild.sh`.
See `BUILD.md` for the patch list and the repack/verify steps.

## OrangeFox 16.0 (source)

```bash
git clone https://gitlab.com/OrangeFox/sync.git
cd sync
./orangefox_sync.sh --branch 16.0 --path ~/fox_16.0
# copy this tree to ~/fox_16.0/device/motorola/vegas26, then:
cd ~/fox_16.0
source build/envsetup.sh
lunch twrp_vegas26-bp2a-eng        # verify the combo after sync
mka vendorbootimage -j16           # or recoveryimage, depending on the tree
```

## Cautions

- Never relock the bootloader with modified `lk`/`init_boot`.
- Do not flash another device's recovery/ROM.
- Keep `nvram`, `nvdata`, `seccfg`, `persist`, `frp`, `protect*`, `md1img` private.
- Use the stock `vendor_dlkm` Focaltech FT8725 module for touch on this board.
- Back up `super` before any GSI experiment.

## Credits

See the docs repo `CREDITS.md`. This tree is derived from public Nevada/Kansas work
(`crabcakes97`, `evoxdl`, Hovatek) and the XDA recovery thread.
