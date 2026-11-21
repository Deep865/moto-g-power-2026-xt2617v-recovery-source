# Scripts

These are the exact scripts used during this work on an `XT2617V` (`vegas26`).
They are **not turnkey**: replace every `<you>` path and provide the AOSP/TWRP tree and
the base OrangeFox image. Nothing device-unique is included.

## Build / repack (WSL2 Ubuntu 22.04)

| Script | Purpose |
|---|---|
| `10-build-14.1.sh` | full TWRP 14.1 build: apt deps, `repo init/sync`, copy device tree, apply A14 fixes, `lunch twrp_vegas26-ap2a-eng`, `mka vendorbootimage` |
| `11-rebuild.sh` | incremental rebuild with the same fixes (no apt/sync) |
| `50-build-hybrid.sh` | stock A16 vendor ramdisk + TWRP 14.1 `recovery` binary/libs, single-platform repack |
| `60-repack-ofox-touch.sh` | replace OrangeFox's focaltech module with the stock FT8725 module, rebuild the two-fragment vendor_boot |
| `verify_built.py` | header/DTB/fragment verification against the stock image |
| `extract_frags.py` | dump vendor_boot fragments (and the largest recovery fragment) |
| `state.sh`, `kill-build.sh` | long-build supervisor helpers |

Assumptions:

- TWRP tree at `/root/twrp` (see `docs/02-recovery.md`).
- OrangeFox extraction at `/root/ofox` (`rec/`, `plat/`, `frags/`).
- Stock revert at `<MotoRoot>/revert/vendor_boot_a.img`.
- Device tree at `<MotoRoot>/device-tree`, copied to `device/motorola/vegas26`.
- `mkbootimg` at `/root/twrp/out/host/linux-x86/bin/mkbootimg`.

Run with `bash <script>`, not `sh`.

## Phone (ADB, root)

| Script | Purpose |
|---|---|
| `backup-dd.sh` | `dd` all key partitions to `/data/local/tmp/backup-YYYYMMDD` and write `SHA256SUMS.txt` |
| `backup-sizes.sh` | list partition sizes and free space |
| `ofox-touch.sh` | mount the real `vendor_dlkm` (`erofs`) and list stock touch modules |
| `ofox-touch2.sh` | unload the image's modules, load the stock focaltech module, show input devices |

Push and run:

```powershell
adb push backup-dd.sh /tmp/backup-dd.sh
adb shell su -c 'sh /tmp/backup-dd.sh'
```

## Verification examples

```bash
python3 verify_built.py vendor_boot.img revert/vendor_boot_a.img
python3 extract_frags.py vendor_boot.img /tmp/frags
```

`verify_built.py` checks magic, header version, page size, kernel/ramdisk addresses,
DTB size and SHA-256, total size, and the fragment layout against the stock image.

## Cautions

- `backup-dd.sh` includes `nvram`, `nvdata`, `seccfg`, `persist`, `frp`, `protect*` and
  `md1img`. Keep those private.
- The build scripts patch the AOSP tree after sync (CTS assets, `-ndk` names, libtar FBE,
  FDE stubs, `libbase`, `libscrypt_static`). Re-running them is idempotent.
- Do not flash anything without verifying the header/DTB and keeping a stock revert.
