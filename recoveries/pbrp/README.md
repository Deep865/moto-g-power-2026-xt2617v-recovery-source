# PBRP 4.x

Pitch Black Recovery Project, built from the **12.1** PBRP manifest. It is
TWRP-based with a different, more colourful UI. Same hardware support as the other
two.

## Fetch the base once

From the root of this repo:

```bash
RECOVERIES="pbrp" ./scripts/fetch-sources.sh
```

That fetches PBRP 12.1 into `$HOME/recovery-sources/pbrp_12.1`.

## Build

```bash
export DEVICE_TREE=$PWD
export OUT_DIR=$HOME/recovery-images
mkdir -p "$OUT_DIR"

PBRP_TREE=$HOME/recovery-sources/pbrp_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/93-build-pbrp12.sh"
```

The script creates `pb_vegas26.mk` (inherits `vendor/pb`), adds `pb_vegas26-eng` to
`AndroidProducts.mk`, copies the device tree, fixes the gatekeeper symlinks and
builds:

```text
lunch pb_vegas26-eng
mka vendorbootimage -j16
```

## Output

```text
$OUT_DIR/PBRP-4.x-vegas26.img
54.9 MB content, padded to 67,108,864 bytes
SHA-256 c899f61ee38ad14ecccd352fa06fcf9e61737698487eb83001ec4a3d95d977cb
```

A fresh build may differ by build ID. Verify before flashing.

## Flash and test

```powershell
fastboot flash vendor_boot_a PBRP-4.x-vegas26.img
```

Enter via **bootloader menu → Volume Down → Recovery mode → Power**. Test FT8725
touch, `/data` decrypt, backup and MTP.

## Notes

- 17/17 on-device self-test on 2026-11-22.
- The PBRP manifest provides `vendor/pb`; the script creates the product makefile.
- No `/cache` partition; only Dalvik/ART is available.
