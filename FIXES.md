# Where every fix is applied

The short answer: **the old `patches/12.1/*.patch` files are not applied any more.**
They were folded into the pinned OrangeFox 12.1 core. The device-tree fixes are
already files in this repo, and the only source patch during the build is the
OrangeFox UPX change.

## 1. Device-tree fixes — stored as files, copied by the builder

These are committed in this repo under `recovery/`, `prebuilt/`, `*.mk`, etc. The
builders copy the whole tree with:

```bash
rsync -a --exclude .git "$DEVICE_TREE"/ device/motorola/vegas26/
```

| Fix | File / path |
|---|---|
| LF `prepdecrypt.sh` | `recovery/root/system/bin/prepdecrypt.sh` |
| real gatekeeper symlinks | `recovery/root/vendor/lib64/hw/gatekeeper.*.so` |
| minimal fstab | `recovery/root/system/etc/recovery.fstab` |
| haptic load order | `recovery/root/init.recovery.mt6835.rc` |
| sideload `adbd` stop / USB gadget | `recovery/root/init.recovery.usb.rc` |
| FT8725 stock touch module | `recovery/root/lib/modules/focaltech_0flash_mmi_v3.ko` and the `vendor_dlkm` copy |
| six panel modules | `recovery/root/lib/modules/dsi-panel-mot-*` |
| DTB / board config | `prebuilt/dtb.img`, `BoardConfig.mk`, `device.mk` |

Applied by: **all three scripts** (`91`, `92`, `93`) at the copy step.

## 2. OrangeFox 12.1 core fixes — pinned upstream commit

The two former hand patches and the newer fixes are in the exact commit that `91`
checks out:

```text
8cd9df2b4cbbbf99acc3182faaa8d0f10cee9779
Fix thermal sensor reading/unsigned integer wrap for cpu temperature
```

That commit contains:

- skip the data-size scan before decryption
- alternate `/dev/block/bootdevice/by-name` / `/dev/block/by-name` paths
- thermal-sensor unsigned-wrap fix
- bzip2 (`TW_EXCLUDE_BZIP2`)
- configurable vibration defaults (`OF_VIBRATION_DEFAULTS`)
- Reboot Recovery after actions
- optional double-tap-to-wake (`FOX_NO_BLANK_DT2W`)

`scripts/91` does:

```bash
git -C bootable/recovery checkout -q "$FOX_CORE_REV"
git -C bootable/recovery reset -q --hard "$FOX_CORE_REV"
scripts/verify-core.sh
```

Pinning the exact commit is why it is no longer patched again. `patches/12.1/` is
kept only for history/review; applying it on top of `8cd9df2b4` would fail because
the commits are already ancestors.

A full source tarball of this exact core is preserved at:
`third_party/bootable-recovery-8cd9df2b4.tar.xz`.

## 3. Build-time source edits

| Edit | Where | Script |
|---|---|---|
| skip UPX compression | `vendor/recovery/OrangeFox_vendor.sh`: `FOX_SKIP_UPX=1` guard | `91`, lines near the top |
| real gatekeeper symlinks | `device/motorola/vegas26/recovery/root/vendor/lib64/hw/` | `91`, `92`, `93` |
| add platform 16 to CTS lists | `cts/tests/tests/os/assets/platform_*` | `91`, `92`, `93` |
| create PBRP product | `device/motorola/vegas26/pb_vegas26.mk` + `AndroidProducts.mk` | `93` |
| no core edits | TWRP/PBRP use their 12.1 trees as-is | `92`, `93` |

## 4. The build output

```text
lunch omni_vegas26-eng   # OrangeFox
lunch twrp_vegas26-eng   # TWRP
lunch pb_vegas26-eng     # PBRP
mka vendorbootimage -j16
```

Then `vendor_boot.img` is copied to `$OUT_DIR/<recovery>-vegas26.img` and hashed.
`extract_frags.py` checks the header/DTB/fragments; `recovery-selftest.sh` checks
the running recovery.

## 5. What is checked

`scripts/verify-core.sh` fails the OrangeFox build unless the pinned core still
contains the expected code: data-size skip, alternate block paths, thermal fix,
bzip2, vibration defaults, reboot-recovery and double-tap-to-wake. If the upstream
commit is ever different, the build stops instead of silently losing a fix.
