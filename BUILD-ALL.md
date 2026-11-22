# Build all three recoveries

One device tree (`device/motorola/vegas26`) builds **OrangeFox R12.0**, **TWRP 3.7.1-12**
and **PBRP 4.x** for the Moto G Power 2026 (`XT2617V`, `vegas26`). All three use the
**12.1** Android base; 14.1/16.0 do not boot on this A16 vendor.

## Prerequisites

- Linux or WSL2 Ubuntu 22.04, 24 GB RAM, ~120 GB free, 16 jobs.
- `repo`, `git`, `bc bison build-essential ccache curl flex g++-multilib gcc-multilib
  lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5
  libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool
  squashfs-tools xsltproc zip zlib1g-dev python3 python-is-python3 openjdk-17-jdk cpio`.
- Platform-tools 35.0.0 or 37.0.1 on the PC (37.0.3 can stall on `flash`).

```bash
export DEVICE_TREE=/path/to/moto-g-power-2026-xt2617v-recovery-source
export OUT_DIR=$PWD/out-images
mkdir -p "$OUT_DIR"
```

## 1. OrangeFox R12.0 (recommended daily)

```bash
git clone https://gitlab.com/OrangeFox/sync.git
cd sync
./orangefox_sync.sh --branch 12.1 --path ~/fox_12.1

FOX_TREE=~/fox_12.1 DEVICE_TREE="$DEVICE_TREE" OUT_DIR="$OUT_DIR" \
  "$DEVICE_TREE/scripts/91-build-ofox12-recovery.sh"
```

`91` pins `bootable/recovery` to `3fc9e73f`, applies the two 14.1 backports from
`patches/12.1/`, skips UPX, fixes the gatekeeper symlinks, and builds with
`FOX_EXTREME_SIZE_REDUCTION=0`.

Output: `$OUT_DIR/OrangeFox-R12.0-vegas26.img`.

## 2. TWRP 3.7.1-12

```bash
mkdir -p ~/twrp_12.1 && cd ~/twrp_12.1
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags

TWRP_TREE=~/twrp_12.1 DEVICE_TREE="$DEVICE_TREE" OUT_DIR="$OUT_DIR" \
  "$DEVICE_TREE/scripts/92-build-twrp12.sh"
```

Output: `$OUT_DIR/TWRP-3.7.1-12-vegas26.img`.

## 3. PBRP 4.x

```bash
mkdir -p ~/pbrp_12.1 && cd ~/pbrp_12.1
repo init --depth=1 -u https://github.com/PitchBlackRecoveryProject/manifest_pb -b android-12.1
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags

PBRP_TREE=~/pbrp_12.1 DEVICE_TREE="$DEVICE_TREE" OUT_DIR="$OUT_DIR" \
  "$DEVICE_TREE/scripts/93-build-pbrp12.sh"
```

`93` creates `pb_vegas26.mk` (inherits `vendor/pb`) and adds `pb_vegas26-eng`.

Output: `$OUT_DIR/PBRP-4.x-vegas26.img`.

## Device-tree fixes carried by this repo

These are why the source builds boot; do not remove them:

| File | Fix |
|---|---|
| `recovery/root/system/bin/prepdecrypt.sh` | LF shebang (`#!/sbin/sh`), not CRLF |
| `recovery/root/vendor/lib64/hw/gatekeeper.trustonic.so` | symlink to `libMcGatekeeper.so` |
| `recovery/root/vendor/lib64/hw/gatekeeper.default.so` | symlink to `libSoftGatekeeper.so` |
| `recovery/root/system/etc/recovery.fstab` | minimal working TWRP fstab |
| `recovery/root/init.recovery.mt6835.rc` | `regulator-vibrator` then `aw862x` at early-init |
| `recovery/root/init.recovery.usb.rc` | sideload stops `adbd`, configures the gadget |
| `recovery/root/init.recovery.usb.rc` | LF, UTF-8 text |

`91` also sets `FOX_SKIP_UPX=1` (OrangeFox's build always UPX-compresses
`/sbin` and `/system/bin`; the packed `init`/`recovery` never reached the UI here).

## Size limit

The bootloader accepts roughly **55.5 MB** of `vendor_boot` content. The 12.1 builds
fit (OrangeFox ~55.1 MB, TWRP ~52.8 MB, PBRP ~55.1 MB). Do not add large fonts or the
full stock module set; the 203-module set in this tree is the working one.

## Verify

```bash
python3 scripts/extract_frags.py "$OUT_DIR/OrangeFox-R12.0-vegas26.img" /tmp/frags
```

Expected: `VENDOR_BOOT_HDR`, header 4, page 4096, DTB `183530`, two fragments
(`platform` + `recovery`), total under 67,108,864.

## Flash

```powershell
fastboot flash vendor_boot_a <image>
```

Then bootloader → **Recovery mode** → Power. `fastboot reboot recovery` boots Android
on this unit. Keep the stock `vendor_boot` for revert.
