# Build everything from this repository

Everything **we changed** is here. You do not need to browse another Git project,
copy files by hand, or re-create a patch. The only external step is one script that
fetches the AOSP / recovery base trees (they are far too large to store here).

## 1. Get this repo

```bash
git clone https://github.com/Deep865/moto-g-power-2026-xt2617v-walmart-recovery-source.git
cd moto-g-power-2026-xt2617v-walmart-recovery-source
```

## 2. Fetch the base trees once

```bash
./scripts/fetch-sources.sh
```

Default destination: `$HOME/recovery-sources`.

```text
$HOME/recovery-sources/fox_12.1
$HOME/recovery-sources/twrp_12.1
$HOME/recovery-sources/pbrp_12.1
```

Disk: ~120 GB. Time: hours. Linux or WSL2 Ubuntu 22.04. See
[`BUILD-ALL.md`](BUILD-ALL.md) for the package list and RAM guidance.

You can build only one recovery:

```bash
RECOVERIES="orangefox" ./scripts/fetch-sources.sh
```

## 3. Build

### OrangeFox

```bash
export DEVICE_TREE=$PWD
export OUT_DIR=$HOME/recovery-images
mkdir -p "$OUT_DIR"

FOX_TREE=$HOME/recovery-sources/fox_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/91-build-ofox12-recovery.sh"
```

### TWRP

```bash
TWRP_TREE=$HOME/recovery-sources/twrp_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/92-build-twrp12.sh"
```

### PBRP

```bash
PBRP_TREE=$HOME/recovery-sources/pbrp_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/93-build-pbrp12.sh"
```

### All three

```bash
DEVICE_TREE=$PWD \
FOX_TREE=$HOME/recovery-sources/fox_12.1 \
TWRP_TREE=$HOME/recovery-sources/twrp_12.1 \
PBRP_TREE=$HOME/recovery-sources/pbrp_12.1 \
OUT_DIR=$HOME/recovery-images \
  "$DEVICE_TREE/scripts/build-all-three.sh"
```

The scripts copy this device tree into the recovery checkout and apply the local
fixes. Do not copy it manually.

## What is stored in this repo

| Path | Why it matters |
|---|---|
| `recovery/`, `prebuilt/`, `BoardConfig.mk`, `*.mk` | the actual `vegas26` device tree |
| `scripts/91`, `92`, `93`, `build-all-three.sh` | working builders for all three recoveries |
| `scripts/recovery-selftest.sh` | the 17/17 on-device test |
| `patches/12.1/` | historical 14.1 backports, now upstream in the pinned 12.1 core |
| `sources.lock` | exact upstream URLs, branches, manifest commits and core hash |
| `third_party/bootable-recovery-8cd9df2b4.tar.xz` | preserved copy of the exact OrangeFox recovery core |
| `third_party/bootable-recovery-twrp-12.1-5c3d206.tar.xz` | preserved TWRP 12.1 core |
| `third_party/bootable-recovery-pbrp-12.1-c3ee88a.tar.xz` | preserved PBRP 12.1 core |
| `experimental/` | 14.1/16.0 history and the backport roadmap, not shipped |

## What is not stored here

- The full AOSP / recovery manifest trees (tens of GB). `fetch-sources.sh` gets them.
- The kernel / vendor blobs, which come from the stock firmware and are already in the
  device tree as needed.
- Your own `init_boot`/`vbmeta` backups, serial, keys, IMEI or `md1img`.

## Verify

```bash
python3 scripts/extract_frags.py "$OUT_DIR/OrangeFox-R12.0-vegas26.img" /tmp/frags
```

Expected: `VNDRBOOT`, header 4, page 4096, DTB `183530`, two fragments
(`platform` + `recovery`), 67,108,864 bytes total.

## Credits / licences

The device tree is derived from public Nevada/Kansas work and the XDA recovery
thread. OrangeFox, TWRP and PBRP are separate upstream projects; their licences are
in their trees. The preserved `bootable/recovery` tarball is the upstream GPL code at
the pinned commit. See `third_party/README.md` and the docs repo `CREDITS.md`.
