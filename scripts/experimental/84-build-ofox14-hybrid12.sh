#!/bin/bash
# 14.1 slim2 recovery on the proven R12.0 platform.
set -e
ROOT=/mnt/c/Users/Deep/MotoRoot
W=/root/ofox14_hybrid
OUT=$ROOT/wsl-build/vendor_boot_ofox14_hybrid12plat.img
TOOLS=/root/twrp/out/host/linux-x86/bin
DTB=/root/twrp/device/motorola/vegas26/prebuilt/dtb.img

rm -rf "$W"; mkdir -p "$W"
python3 "$ROOT/scripts/extract_frags.py" "$ROOT/wsl-build/vegas_ofox_fixed.img" "$W/f12" >/dev/null
PLAT="$W/f12/frag_0_type1_noname.lz4"
REC=/root/ofox14_slim2.lz4
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
