# TWRP 3.7.1-12

Plain TWRP from the minimal TWRP **12.1** manifest. Smallest of the three working
images and the most familiar UI. No OrangeFox-specific patches are needed.

## Fetch the base once

From the root of this repo:

```bash
RECOVERIES="twrp" ./scripts/fetch-sources.sh
```

That fetches TWRP 12.1 into `$HOME/recovery-sources/twrp_12.1`.

## Build

```bash
export DEVICE_TREE=$PWD
export OUT_DIR=$HOME/recovery-images
mkdir -p "$OUT_DIR"

TWRP_TREE=$HOME/recovery-sources/twrp_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/92-build-twrp12.sh"
```

The script copies the device tree, fixes the gatekeeper symlinks, builds:

```text
lunch twrp_vegas26-eng
mka vendorbootimage -j16
```

## Output

```text
$OUT_DIR/TWRP-3.7.1-12-vegas26.img
52.8 MB content, padded to 67,108,864 bytes
SHA-256 0a241558f40d4cd18b0b2299d0018ac0154362045691b329c8bfb4a6d562c5d7
```

A fresh build may differ by build ID. Verify the header/DTB/fragments before
flashing.

## Flash and test

```powershell
fastboot flash vendor_boot_a TWRP-3.7.1-12-vegas26.img
```

Enter via **bootloader menu → Volume Down → Recovery mode → Power**. Test FT8725
touch, `/data` decrypt with the PIN and a backup to `/sdcard/TWRP/BACKUPS`.

## Notes

- 17/17 on-device self-test on 2026-11-22.
- No `/cache` partition; only Dalvik/ART under Wipe → Advanced.
- The source tree is 12.1, not the non-working TWRP 14.1 experiment.
