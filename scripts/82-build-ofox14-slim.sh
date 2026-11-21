#!/bin/bash
# Trim the built OrangeFox 14.1 recovery to the working recovery's size envelope.
set -e
ROOT=/mnt/c/Users/Deep/MotoRoot
SRC=/root/ofox14_compare/rec
R12=/root/ofox/rec
W=/root/ofox14_slim
OUT=$ROOT/wsl-build/vendor_boot_ofox14_slim.img
TOOLS=/root/twrp/out/host/linux-x86/bin
DTB=/root/twrp/device/motorola/vegas26/prebuilt/dtb.img

rm -rf "$W"
cp -a "$SRC" "$W"

# Working 207-module recovery set, including the six dsi-panel modules.
rm -rf "$W/lib/modules"
cp -a "$R12/lib/modules" "$W/lib/modules"

# Stock FT8725 in every touch path.
for d in lib/modules vendor/lib/modules vendor_dlkm/lib/modules; do
  mkdir -p "$W/$d"
  cp -f "$R12/vendor/lib/modules/focaltech_0flash_mmi_v3.ko" "$W/$d/focaltech_0flash_mmi_v3.ko"
  chmod 644 "$W/$d/focaltech_0flash_mmi_v3.ko"
done

# The working image does not carry the second fallback font.
rm -f "$W/twres/fonts/DroidSansFallback.ttf"

echo '--- modules/panels/touch ---'
du -sh "$W/lib/modules"
ls "$W/lib/modules" | grep 'dsi-panel' | wc -l
md5sum "$W/lib/modules/focaltech_0flash_mmi_v3.ko" \
       "$W/vendor/lib/modules/focaltech_0flash_mmi_v3.ko" \
       "$W/vendor_dlkm/lib/modules/focaltech_0flash_mmi_v3.ko"

( cd "$W" && find . | cpio -o -H newc --owner=0:0 2>/dev/null \
    | lz4 -l -12 --favor-decSpeed > /root/ofox14_slim.lz4 )
ls -l /root/ofox14_slim.lz4

"$TOOLS/mkbootimg" --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
  --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
  --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
  --dtb "$DTB" \
  --vendor_cmdline "bootopt=64S3,32N2,64N2" \
  --vendor_ramdisk /root/ofox14_compare/frags/frag_0_type1_noname.lz4 \
  --ramdisk_type recovery --ramdisk_name recovery \
  --vendor_ramdisk_fragment /root/ofox14_slim.lz4 \
  --vendor_boot "$OUT"
truncate -s 67108864 "$OUT"
ls -lh "$OUT"
sha256sum "$OUT"

python3 "$ROOT/scripts/verify_built.py" "$OUT" "$ROOT/revert/vendor_boot_a.img"
