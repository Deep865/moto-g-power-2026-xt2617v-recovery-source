#!/bin/bash
# Diagnostic hybrids for the OrangeFox 16.0 boot failure.
# A: known-good 14.1 platform + 16.0 slim recovery  (does the 16.0 recovery work?)
# B: 16.0 platform + known-good 14.1 recovery      (does the 16.0 platform work?)
set -e
ROOT=/mnt/c/Users/Deep/MotoRoot
OUT=$ROOT/wsl-build
W=/root/ofox16_hybrid
TOOLS=/root/twrp/out/host/linux-x86/bin
DTB=/root/twrp/device/motorola/vegas26/prebuilt/dtb.img
PLAT14=/root/ofox/frags/frag_0_type1_noname.lz4
REC14=/root/ofox/frags/frag_1_type2_recovery.lz4
PLAT16=/root/ofox16_slim_work/frags/frag_0_type1_noname.lz4
REC16=/root/ofox16_slim_work/recovery_slim.lz4

rm -rf "$W"; mkdir -p "$W"
python3 "$ROOT/scripts/extract_frags.py" "$ROOT/wsl-build/vegas_ofox_fixed.img" "$W/f14" >/dev/null
PLAT14="$W/f14/frag_0_type1_noname.lz4"
REC14="$W/f14/frag_1_type2_recovery.lz4"
ls -l "$PLAT14" "$REC14" "$PLAT16" "$REC16"

pack() {
  name=$1 plat=$2 rec=$3
  "$TOOLS/mkbootimg" --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
    --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
    --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
    --dtb "$DTB" \
    --vendor_cmdline "bootopt=64S3,32N2,64N2" \
    --vendor_ramdisk "$plat" \
    --ramdisk_type recovery --ramdisk_name recovery \
    --vendor_ramdisk_fragment "$rec" \
    --vendor_boot "$OUT/$name.img"
  truncate -s 67108864 "$OUT/$name.img"
  ls -lh "$OUT/$name.img"
  sha256sum "$OUT/$name.img"
  python3 "$ROOT/scripts/verify_built.py" "$OUT/$name.img" "$ROOT/revert/vendor_boot_a.img"
}

echo '===== A: 14.1 platform + 16.0 recovery ====='
pack vendor_boot_ofox16_hybrid14plat "$PLAT14" "$REC16"
echo '===== B: 16.0 platform + 14.1 recovery ====='
pack vendor_boot_hybrid16plat14rec "$PLAT16" "$REC14"
