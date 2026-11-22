#!/bin/bash
# Font-kept 16.0 recovery on the proven 14.1 platform.
# The slim A image removed the Chinese theme font and never reached the menu.
# This build keeps the font and instead drops recovery Wi-Fi, debug modules and
# three unused panel variants, plus the haptic firmware, to stay under the size
# of the known-good 14.1 image.
set -e
ROOT=/mnt/c/Users/Deep/MotoRoot
SRC=/root/ofox16verify/rec
W=/root/ofox16_fontkept
OUT=$ROOT/wsl-build/vendor_boot_ofox16_fontkept14plat.img
TOOLS=/root/twrp/out/host/linux-x86/bin
DTB=/root/twrp/device/motorola/vegas26/prebuilt/dtb.img

rm -rf "$W"
cp -al "$SRC" "$W"
rm -f "$W/vendor/firmware/haptic_nv_rtp_silk.bin" \
      "$W/vendor/firmware/haptic_nv_rtp_lighthouse.bin" \
      "$W/vendor/firmware/haptic_nv_rtp.bin"
rm -f "$W/lib/modules/cfg80211.ko" "$W/lib/modules/mac80211.ko"
rm -f "$W/lib/modules/isee.ko" "$W/lib/modules/mrdump.ko" "$W/lib/modules/iommu_debug.ko"
rm -f \
  "$W/lib/modules/dsi-panel-mot-vdo-tm-ili77600a-1080-2388-dphy-120hz.ko" \
  "$W/lib/modules/dsi-panel-mot-vdo-tm-ili7807s-1080-2388-dphy-120hz.ko" \
  "$W/lib/modules/dsi-panel-mot-vdo-txd-nt36672c-1080-2388-dphy-120hz.ko"

( cd "$W" && find . | cpio -o -H newc --owner=0:0 2>/dev/null \
    | lz4 -l -12 --favor-decSpeed > /root/ofox16_fontkept.lz4 )
ls -l /root/ofox16_fontkept.lz4

mkdir -p "$W/frags"
python3 "$ROOT/scripts/extract_frags.py" "$ROOT/wsl-build/vegas_ofox_fixed.img" "$W/frags" >/dev/null
PLAT="$W/frags/frag_0_type1_noname.lz4"

"$TOOLS/mkbootimg" --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
  --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
  --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
  --dtb "$DTB" \
  --vendor_cmdline "bootopt=64S3,32N2,64N2" \
  --vendor_ramdisk "$PLAT" \
  --ramdisk_type recovery --ramdisk_name recovery \
  --vendor_ramdisk_fragment /root/ofox16_fontkept.lz4 \
  --vendor_boot "$OUT"
truncate -s 67108864 "$OUT"
ls -lh "$OUT"
sha256sum "$OUT"

echo '--- font kept? ---'
ls -l "$W/twres/fonts/wqy-microhei.ttf"
echo '--- haptic removed (expect error) ---'
ls "$W/vendor/firmware/haptic_nv_rtp.bin" 2>&1 || true
echo '--- kept touch/panel ---'
ls -l "$W/lib/modules/focaltech_0flash_mmi_v3.ko" \
      "$W/lib/modules/dsi-panel-mot-vdo-txd-ft8725-1080-2388-dphy-fhd-120hz.ko"
echo '--- module count ---'
ls "$W/lib/modules"/*.ko | wc -l
python3 "$ROOT/scripts/verify_built.py" "$OUT" "$ROOT/revert/vendor_boot_a.img"
