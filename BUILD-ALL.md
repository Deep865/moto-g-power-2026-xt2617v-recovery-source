# Build the working recoveries

This tree builds **OrangeFox R12.0**, **TWRP 3.7.1-12** and **PBRP 4.x** for the
Moto G Power 2026 (`XT2617V`, `vegas26`) from one device tree. You can build **any
one** of them; you do not need all three. All use the **12.1** base because that is
what boots on this Android 16 vendor.

| Recovery | Script | Manifest | Output |
|---|---|---|---|
| OrangeFox R12.0 | `scripts/91-build-ofox12-recovery.sh` | OrangeFox sync `12.1` | `OrangeFox-R12.0-vegas26.img` |
| TWRP 3.7.1-12 | `scripts/92-build-twrp12.sh` | TWRP minimal `twrp-12.1` | `TWRP-3.7.1-12-vegas26.img` |
| PBRP 4.x | `scripts/93-build-pbrp12.sh` | PBRP `android-12.1` | `PBRP-4.x-vegas26.img` |

## Host

Linux or WSL2 Ubuntu 22.04, 16–24 GB RAM, ~120 GB free disk, 16 jobs. A 16 GB host
can OOM during Soong analysis; close other VMs and use `-j8` if needed.

```bash
sudo apt update
sudo apt install -y bc bison build-essential ccache curl flex g++-multilib \
  gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev \
  lib32z1-dev libelf-dev liblz4-tool libncurses5 libsdl1.2-dev libssl-dev \
  libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc \
  zip zlib1g-dev python3 python-is-python3 openjdk-17-jdk cpio
```

`repo` must be installed and on `PATH`. Use platform-tools 35.0.0 or 37.0.1 on the
PC for flashing; 37.0.3 can stall on `flash`.

```bash
git clone https://github.com/Deep865/moto-g-power-2026-xt2617v-walmart-recovery-source.git
cd moto-g-power-2026-xt2617v-walmart-recovery-source
./scripts/fetch-sources.sh          # or RECOVERIES="orangefox"

export DEVICE_TREE=$PWD
export OUT_DIR=$HOME/recovery-images
mkdir -p "$OUT_DIR"
```

The default tree root is `$HOME/recovery-sources`. Everything we changed is in this
repo; see [`BUILD-FROM-THIS-REPO.md`](BUILD-FROM-THIS-REPO.md) and
[`sources.lock`](sources.lock). The scripts copy `$DEVICE_TREE` into
`device/motorola/vegas26`, so you do not need to clone it into each manifest tree.

## 1. OrangeFox R12.0

```bash
# only if you did not run the default fetch above:
RECOVERIES="orangefox" ./scripts/fetch-sources.sh

FOX_TREE=$HOME/recovery-sources/fox_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/91-build-ofox12-recovery.sh"
```

The script:

- checks out the latest tested `fox_12.1` core (`8cd9df2b4`), which already
  includes the two former 14.1 backports (skip data-size scan; alternate
  `/dev/block/by-name`) plus thermal, bzip2, vibration-default, reboot-recovery and
  double-tap-to-wake fixes;
- no longer applies the old `patches/historical-12.1/` by hand; they are upstream now;
- patches `vendor/recovery/OrangeFox_vendor.sh` to honour `FOX_SKIP_UPX=1`;
- makes `gatekeeper.*.so` real symlinks;
- adds `16` to the CTS platform lists;
- builds `lunch omni_vegas26-eng` + `mka vendorbootimage`.

Output: `$OUT_DIR/OrangeFox-R12.0-vegas26.img`.

## 2. TWRP 3.7.1-12

```bash
# only if you did not run the default fetch above:
RECOVERIES="twrp" ./scripts/fetch-sources.sh

TWRP_TREE=$HOME/recovery-sources/twrp_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/92-build-twrp12.sh"
```

Output: `$OUT_DIR/TWRP-3.7.1-12-vegas26.img`.

## 3. PBRP 4.x

```bash
# only if you did not run the default fetch above:
RECOVERIES="pbrp" ./scripts/fetch-sources.sh

PBRP_TREE=$HOME/recovery-sources/pbrp_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/93-build-pbrp12.sh"
```

`93` creates `pb_vegas26.mk` (inheriting `vendor/pb`) and adds
`pb_vegas26-eng` to the lunch choices.

Output: `$OUT_DIR/PBRP-4.x-vegas26.img`.

## Build all three

After syncing the three trees:

```bash
DEVICE_TREE=$DEVICE_TREE \
FOX_TREE=$HOME/recovery-sources/fox_12.1 \
TWRP_TREE=$HOME/recovery-sources/twrp_12.1 \
PBRP_TREE=$HOME/recovery-sources/pbrp_12.1 \
OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/build-all-three.sh"
```

Build a subset with `RECOVERIES="orangefox pbrp"` (space-separated).

## Device-tree fixes carried by this repo

These are why the source builds boot; do not remove them:

| File | Fix |
|---|---|
| `recovery/root/system/bin/prepdecrypt.sh` | LF shebang (`#!/sbin/sh`), not CRLF |
| `recovery/root/vendor/lib64/hw/gatekeeper.trustonic.so` | symlink to `libMcGatekeeper.so` |
| `recovery/root/vendor/lib64/hw/gatekeeper.default.so` | symlink to `libSoftGatekeeper.so` |
| `recovery/root/system/etc/recovery.fstab` | minimal working TWRP fstab |
| `recovery/root/init.recovery.mt6835.rc` | `regulator-vibrator` then `aw862x` at early-init |
| `recovery/root/init.recovery.usb.rc` | sideload stops `adbd`, configures the gadget; LF text |

`91` also sets `FOX_SKIP_UPX=1`; OrangeFox otherwise UPX-compresses `/sbin` and
`/system/bin` and the packed `init`/`recovery` never reach the UI here.

## Size limit

The bootloader accepts roughly **55.5 MB** of `vendor_boot` content. The tested 12.1
builds fit (OrangeFox ~55.2 MB, TWRP ~52.8 MB, PBRP ~54.9 MB). Do not add large
fonts or the full stock module set; the 203-module set in this tree is the working
one.

## Verify

```bash
python3 "$DEVICE_TREE/scripts/extract_frags.py" \
  "$OUT_DIR/OrangeFox-R12.0-vegas26.img" /tmp/frags
```

Expected: `VNDRBOOT`, header 4, page 4096, DTB `183530` bytes, two fragments
(`platform` + `recovery`), total 67,108,864 bytes. `scripts/verify_built.py` can
compare a fresh image with a known-good/stock image.

## Flash and test

```powershell
fastboot flash vendor_boot_a <image>.img
```

Then **bootloader menu → Volume Down → Recovery mode → Power**. `fastboot reboot
recovery` boots Android on this unit. Keep the stock `vendor_boot_a` for revert.

The on-device self-test is `scripts/recovery-selftest.sh`; push it to `/tmp`, run it
in the recovery shell, and read `/tmp/recovery_selftest.txt`. The Windows harness
used here is `test-recovery.ps1` in the docs repo (PIN 1234 in the test session).

## Not supported: 14.1 / 16.0

Both OrangeFox 14.1 and 16.0 build but do not reach a usable recovery UI on this
A16 vendor, and full images can exceed the size limit. They are **not** part of the
supported build. Historical notes and scripts are in
[`experimental/`](experimental/README.md); useful fixes are tracked in
[`experimental/BACKPORT-ROADMAP.md`](experimental/BACKPORT-ROADMAP.md).

## Flash the published images instead

If you only want a working recovery, do not build at all:
<https://github.com/Deep865/moto-g-power-2026-xt2617v-walmart-unlock-degoogle-guide/releases/tag/2026-11-22>
has the three tested images, the recovery pack and the full walkthrough.
