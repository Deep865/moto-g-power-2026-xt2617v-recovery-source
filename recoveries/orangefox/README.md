# OrangeFox R12.0

The most feature-rich of the three working recoveries. Built from the latest
tested OrangeFox **12.1** core (`8cd9df2b4`) and the device-tree fixes in this repo.
ADB sideload was verified on this image.

## Sync

```bash
git clone https://gitlab.com/OrangeFox/sync.git
cd sync
./orangefox_sync.sh --branch 12.1 --path "$HOME/fox_12.1"
```

## Build

```bash
export DEVICE_TREE=/path/to/moto-g-power-2026-xt2617v-walmart-recovery-source
export OUT_DIR=$HOME/recovery-images
mkdir -p "$OUT_DIR"

FOX_TREE=$HOME/fox_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/91-build-ofox12-recovery.sh"
```

The script pins `bootable/recovery` to `8cd9df2b4`. That core includes the two
former 14.1 backports (skip data-size scan; alternate block paths) and newer fixes:
thermal reading, bzip2, vibration defaults, Reboot Recovery after actions and
optional double-tap-to-wake. It skips UPX, fixes the gatekeeper aliases and builds:

```text
lunch omni_vegas26-eng
mka vendorbootimage -j16
```

## Output

```text
$OUT_DIR/OrangeFox-R12.0-vegas26.img
55.2 MB content, padded to 67,108,864 bytes
SHA-256 86c42c5777109fa818ca1786392d6e3b8ae6aaeddc0d237fb843bb14a956223b
```

A fresh build may differ by build ID. Verify before flashing:

```bash
python3 "$DEVICE_TREE/scripts/extract_frags.py" "$OUT_DIR/OrangeFox-R12.0-vegas26.img" /tmp/ofox
```

## Flash and test

```powershell
fastboot flash vendor_boot_a OrangeFox-R12.0-vegas26.img
```

Enter via **bootloader menu → Volume Down → Recovery mode → Power**. Test touch,
`/data` decrypt and a backup. Revert with the stock `vendor_boot_a`.

## Optional: ADB sideload

```powershell
adb sideload some.zip
```

The device tree stops `adbd` before configuring the sideload gadget. This was tested
on this image (`adb sideload ofox-test.zip` completed).

## Notes

- If OrangeFox opens on the log/console page, rename `/sdcard/Fox/.foxs` to
  `.foxs.bak` and reboot recovery.
- Do not add large fonts or modules; the image is close to the ~55.5 MB content limit.
