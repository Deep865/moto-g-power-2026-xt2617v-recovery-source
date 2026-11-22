# Moto G Power 2026 (`XT2617V`, Walmart / Straight Talk) — recovery source

Build **any of the three working recoveries** for the Walmart / Straight Talk
Moto G Power 2026 from **one device tree**:

| Recovery | Build script | Manifest / branch | Output |
|---|---|---|---|
| **OrangeFox R12.0** | `scripts/91-build-ofox12-recovery.sh` | OrangeFox sync `12.1` | `OrangeFox-R12.0-vegas26.img` |
| **TWRP 3.7.1-12** | `scripts/92-build-twrp12.sh` | minimal manifest `twrp-12.1` | `TWRP-3.7.1-12-vegas26.img` |
| **PBRP 4.x** | `scripts/93-build-pbrp12.sh` | PBRP `android-12.1` | `PBRP-4.x-vegas26.img` |

All three are `vendor_boot` images for **slot A** and support the same hardware:
Focaltech FT8725 touch, FBE `/data` decryption, backup/restore, MTP/ADB, haptics
and the six 1080×2388 panel modules. Pick by UI; they are equally functional.

- **Choose one:** [`recoveries/README.md`](recoveries/README.md)
- **Build one or all three:** [`BUILD-ALL.md`](BUILD-ALL.md)
- **Where each fix is applied:** [FIXES.md](FIXES.md)
- **Tested binaries and the full phone guide:** <https://github.com/Deep865/moto-g-power-2026-xt2617v-walmart-unlock-degoogle-guide>

This repo is the **source/build** half. The other repo is the **walkthrough/release**
half: SIM-screen bypass, temporary root, LK unlock, Magisk, LineageOS 23.2 microG
GSI, recovery flash, modem unlock, backups and revert.


## Everything needed to rebuild

You only clone **this** repository. One script fetches the upstream AOSP/recovery
base trees; everything we changed is already here.

```bash
git clone https://github.com/Deep865/moto-g-power-2026-xt2617v-walmart-recovery-source.git
cd moto-g-power-2026-xt2617v-walmart-recovery-source
./scripts/fetch-sources.sh          # all three; or RECOVERIES="orangefox"
```

The default destination is `$HOME/recovery-sources`. The exact upstream URLs,
branches, manifest commits and the pinned OrangeFox core are in
[`sources.lock`](sources.lock). Preserved copies of the exact OrangeFox, TWRP and PBRP recovery cores are in
[`third_party/`](third_party/). See
[`BUILD-FROM-THIS-REPO.md`](BUILD-FROM-THIS-REPO.md) for the full no-hunting path.

## Build the one you want

The scripts copy this tree into the recovery source checkout, fix the known
Windows/Linux traps, build `vendor_boot.img` and copy it to `OUT_DIR`. You do not
need to build all three.

### OrangeFox R12.0

```bash
# if not already fetched:
RECOVERIES="orangefox" ./scripts/fetch-sources.sh

export DEVICE_TREE=$PWD
export OUT_DIR=$HOME/recovery-images
mkdir -p "$OUT_DIR"
FOX_TREE=$HOME/recovery-sources/fox_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/91-build-ofox12-recovery.sh"
```

`91` pins `bootable/recovery` to the latest tested `fox_12.1` core (`8cd9df2b4`),
which includes the two former 14.1 backports plus thermal, bzip2, vibration-default,
reboot-recovery and double-tap-to-wake fixes. It disables UPX, fixes the gatekeeper
symlinks and builds with `FOX_EXTREME_SIZE_REDUCTION=0`.

### TWRP 3.7.1-12

```bash
# if not already fetched:
RECOVERIES="twrp" ./scripts/fetch-sources.sh

export DEVICE_TREE=$PWD
export OUT_DIR=$HOME/recovery-images
mkdir -p "$OUT_DIR"
TWRP_TREE=$HOME/recovery-sources/twrp_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/92-build-twrp12.sh"
```

### PBRP 4.x

```bash
# if not already fetched:
RECOVERIES="pbrp" ./scripts/fetch-sources.sh

export DEVICE_TREE=$PWD
export OUT_DIR=$HOME/recovery-images
mkdir -p "$OUT_DIR"
PBRP_TREE=$HOME/recovery-sources/pbrp_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/93-build-pbrp12.sh"
```

### All three

After syncing the three trees above:

```bash
DEVICE_TREE=$PWD \
FOX_TREE=$HOME/recovery-sources/fox_12.1 \
TWRP_TREE=$HOME/recovery-sources/twrp_12.1 \
PBRP_TREE=$HOME/recovery-sources/pbrp_12.1 \
OUT_DIR=$HOME/recovery-images \
  "$DEVICE_TREE/scripts/build-all-three.sh"
```

Set `RECOVERIES="orangefox twrp"` to build a subset.

## What was tested

The published images are from this tree on 2026-11-22 and passed a **17/17** on-device
self-test each (UI, FT8725 touch, FBE decrypt, `/sdcard` read/write, gatekeeper,
haptics, MTP/ADB, six panels). OrangeFox also passed an ADB sideload test.

| Image | Size (content) | SHA-256 |
|---|---:|---|
| `OrangeFox-R12.0-vegas26.img` | 55.2 MB | `9cd709698b444658d5db5bbbe047429bebfc2ce4209e1b08c377d591ff1a24a0` |
| `TWRP-3.7.1-12-vegas26.img` | 52.8 MB | `0a241558f40d4cd18b0b2299d0018ac0154362045691b329c8bfb4a6d562c5d7` |
| `PBRP-4.x-vegas26.img` | 54.9 MB | `c899f61ee38ad14ecccd352fa06fcf9e61737698487eb83001ec4a3d95d977cb` |

Each file is padded to the 64 MiB `vendor_boot_a` partition size. A fresh build may
differ by build ID; verify the fragments and boot it before publishing.

## Why 12.1?

Recovery compatibility here is with the **Android 16 vendor/firmware**, not the Android
version of the recovery branch. The 14.1 and 16.0 OrangeFox branches both reach a
recovery userspace dead end on this unit, and their full images can exceed the
bootloader's ~55.5 MB `vendor_boot` content limit. The 12.1 core boots, decrypts and
backs up reliably, and its newer branch now carries the fixes we used to backport by
hand.

We are **not** shipping 14.1/16.0. We do want to **backport useful fixes** from those
branches into 12.1 where they fit. See
[`experimental/BACKPORT-ROADMAP.md`](experimental/BACKPORT-ROADMAP.md) and the
[`experimental/`](experimental/README.md) folder.

## Why these fixes are in the tree

Do not remove them; each one is the difference between a build and a boot:

| Fix | Why |
|---|---|
| LF line endings in `recovery/root/*` | a CRLF `prepdecrypt.sh` shebang makes init fail with status 127 and hangs the splash |
| real symlinks for `gatekeeper.trustonic.so` / `gatekeeper.default.so` | flattened text files make `dlopen` fail and gatekeeper crash-loop |
| minimal `recovery.fstab` | the stock fstab's duplicate entries make the partition scan hang |
| `regulator-vibrator.ko` before `aw862x_haptic_nv_v1.ko` | wrong order gives `ram init failed` |
| sideload stops `adbd` and configures the gadget | avoids the `adbd` conflict during ADB sideload |
| no UPX on `/sbin` and `/system/bin` | the packed `init`/`recovery` never reach userspace |
| stock FT8725 touch module | the bundled G Play variant fails with `ENODEV` |

## Repo layout

```
README.md                 this file
BUILD-ALL.md              the full build guide for all three
BUILD-FROM-THIS-REPO.md   one-repo clone + fetch + build path
FIXES.md                  map of every change and where it is applied
sources.lock              exact upstream revisions
third_party/              preserved OrangeFox/TWRP/PBRP cores
STATUS.md                 current status and what was tested
recoveries/               per-recovery build sheets
  orangefox/README.md
  twrp/README.md
  pbrp/README.md
patches/historical-12.1/             historical 14.1 backports (now upstream in 8cd9df2b4)
recovery/                 the device tree / recovery ramdisk
prebuilt/                 DTB and prebuilt modules
scripts/
  91-build-ofox12-recovery.sh
  92-build-twrp12.sh
  93-build-pbrp12.sh
  build-all-three.sh
  recovery-selftest.sh
  extract_frags.py
  verify_built.py
  experimental/           historical 14.1/16.0 experiments; not supported
experimental/             notes and the backport roadmap
```

## Verify before flashing

```bash
python3 scripts/extract_frags.py "$OUT_DIR/OrangeFox-R12.0-vegas26.img" /tmp/frags
```

Expected: `VNDRBOOT`, header 4, page 4096, DTB `183530` bytes, two fragments
(`platform` + `recovery`), total 67,108,864 bytes, content under ~55.5 MB.

Flash only to `vendor_boot_a`; never relock the bootloader. Enter recovery from the
bootloader menu: **Volume Down → Recovery mode → Power**. `fastboot reboot recovery`
boots Android on this unit.

## Cautions

- Keep `nvram`, `nvdata`, `seccfg`, `persist`, `frp`, `protect*` and `md1img` private.
- Do not flash another device's recovery.
- Back up stock `vendor_boot_a` before replacing it.
- Build on Linux/WSL2, not a Windows-mounted checkout. The CRLF/symlink traps are real.
- Use platform-tools 35.0.0 or 37.0.1; 37.0.3 can stall.

## Credits

The device tree is derived from public Nevada/Kansas work (`crabcakes97`, `evoxdl`,
Hovatek), the XDA recovery thread, and the OrangeFox/TWRP/PBRP projects. The GSI and
modem path are documented by `qfertig/vegas26-gsi` and `andrewwm/vegas-freedom`.
See the docs repo `CREDITS.md`.
