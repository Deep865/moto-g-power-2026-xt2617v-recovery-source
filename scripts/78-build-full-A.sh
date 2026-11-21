#!/bin/bash
# Full 16.0 recovery on the known-good 14.1 platform: every module, the theme
# font and the haptic firmware retained.  This is the last size-bound variant
# (about 57.45 MB vendor ramdisk) and may hit the bootloader limit.
set -e
ROOT=/mnt/c/Users/Deep/MotoRoot
W=/root/ofox16_fullA
OUT=$ROOT/wsl-build/vendor_boot_ofox16_full14plat.img
TOOLS=/root/twrp/out/host/linux-x86/bin
DTB=/root/twrp/device/motorola/vegas26/prebuilt/dtb.img

rm -rf "$W"; mkdir -p "$W"
python3 "$ROOT/scripts/extract_frags.py" "$ROOT/wsl-build/vegas_ofox_fixed.img" "$W/f14" >/dev/null
python3 "$ROOT/scripts/extract_frags.py" "$ROOT/wsl-build/vendor_boot_ofox16.img" "$W/f16" >/dev/null
PLAT="$W/f14/frag_0_type1_noname.lz4"
REC="$W/f16/frag_1_type2_recovery.lz4"
ls -l "$PLAT" "$REC"

"$TOOLS/mkbootimg" --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
  --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
  --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
  --dtb "$DTB" \
  --vendor_cmdline "bootopt=64S3,32N2,64N2" \
  --vendor_ramdisk "$PLAT" \
  --ramdisk_type recovery --ramdisk_name recovery \
  --vendor_ramdisk_fragment "$REC" \
  --vendor_boot "$OUT"
truncate -s 67108864 "$OUT"
ls -lh "$OUT"
sha256sum "$OUT"
python3 "$ROOT/scripts/verify_built.py" "$OUT" "$ROOT/revert/vendor_boot_a.img"
