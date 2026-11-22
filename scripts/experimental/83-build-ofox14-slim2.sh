#!/bin/bash
# Second trim: remove recovery Wi-Fi, debug modules and haptics to get under the
# proven R12.0 size. Display/touch/storage/USB/TEE/charging stay.
set -e
ROOT=/mnt/c/Users/Deep/MotoRoot
W=/root/ofox14_slim2
OUT=$ROOT/wsl-build/vendor_boot_ofox14_slim2.img
TOOLS=/root/twrp/out/host/linux-x86/bin
DTB=/root/twrp/device/motorola/vegas26/prebuilt/dtb.img

rm -rf "$W"
cp -a /root/ofox14_slim "$W"

rm -f "$W/vendor/firmware/haptic_nv_rtp_silk.bin" \
      "$W/vendor/firmware/haptic_nv_rtp_lighthouse.bin" \
      "$W/vendor/firmware/haptic_nv_rtp.bin"
rm -f "$W/lib/modules/cfg80211.ko" "$W/lib/modules/mac80211.ko"
rm -f "$W/lib/modules/isee.ko" "$W/lib/modules/mrdump.ko" "$W/lib/modules/iommu_debug.ko"

echo '--- panels/touch ---'
ls "$W/lib/modules" | grep 'dsi-panel' | wc -l
md5sum "$W/lib/modules/focaltech_0flash_mmi_v3.ko" \
       "$W/vendor/lib/modules/focaltech_0flash_mmi_v3.ko" \
       "$W/vendor_dlkm/lib/modules/focaltech_0flash_mmi_v3.ko"

( cd "$W" && find . | cpio -o -H newc --owner=0:0 2>/dev/null \
    | lz4 -l -12 --favor-decSpeed > /root/ofox14_slim2.lz4 )
ls -l /root/ofox14_slim2.lz4

"$TOOLS/mkbootimg" --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
  --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
  --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
  --dtb "$DTB" \
  --vendor_cmdline "bootopt=64S3,32N2,64N2" \
  --vendor_ramdisk /root/ofox14_compare/frags/frag_0_type1_noname.lz4 \
  --ramdisk_type recovery --ramdisk_name recovery \
  --vendor_ramdisk_fragment /root/ofox14_slim2.lz4 \
  --vendor_boot "$OUT"
truncate -s 67108864 "$OUT"
ls -lh "$OUT"
sha256sum "$OUT"

python3 "$ROOT/scripts/verify_built.py" "$OUT" "$ROOT/revert/vendor_boot_a.img"
