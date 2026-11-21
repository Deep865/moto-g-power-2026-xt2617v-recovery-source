#!/bin/bash
# Build a size-reduced OrangeFox 16.0 vendor_boot that fits the vegas26 recovery
# budget. The 16.0 build is ~2.8 MB larger than the known-good 14.1 image; the
# bootloader loads the logo and then returns to fastboot without a kernel log,
# which points at the vendor-ramdisk size rather than the header/DTB.
#
# This repack keeps every kernel module (Wi-Fi, all six panel variants, TEE,
# touch, storage, USB, charging) and only drops the Chinese-only theme font and
# the three Richtap haptic firmware blobs.  That removes ~9.5 MB uncompressed
# and brings the vendor ramdisk below the proven 14.1 size.
set -e
ROOT=/mnt/c/Users/Deep/MotoRoot
SRC=$ROOT/wsl-build/vendor_boot_ofox16.img
STOCK=$ROOT/revert/vendor_boot_a.img
OUT=$ROOT/wsl-build/vendor_boot_ofox16_slim.img
W=/root/ofox16_slim_work
TOOLS=/root/fox_16.0/out/host/linux-x86/bin
DTB=/root/fox_16.0/device/motorola/vegas26/prebuilt/dtb.img

rm -rf "$W"
mkdir -p "$W/frags" "$W/root"
python3 "$ROOT/scripts/extract_frags.py" "$SRC" "$W/frags"
lz4 -d "$W/frags/recovery_ramdisk.lz4" "$W/recovery.cpio" >/dev/null
( cd "$W/root" && cpio -idm --no-absolute-filenames < ../recovery.cpio >/dev/null 2>&1 )

# Drop the Chinese-only font and the haptic firmware blobs.  English/other
# Latin text uses the normal theme fonts; touch, display and vibration-less
# recovery operation are unaffected.
rm -f "$W/root/twres/fonts/wqy-microhei.ttf"
rm -f "$W/root/vendor/firmware/haptic_nv_rtp_silk.bin" \
      "$W/root/vendor/firmware/haptic_nv_rtp_lighthouse.bin" \
      "$W/root/vendor/firmware/haptic_nv_rtp.bin"

( cd "$W/root" && find . | cpio -o -H newc --owner=0:0 2>/dev/null \
    | lz4 -l -12 --favor-decSpeed > "$W/recovery_slim.lz4" )
ls -l "$W/recovery_slim.lz4"

"$TOOLS/mkbootimg" --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
  --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
  --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
  --dtb "$DTB" \
  --vendor_cmdline "bootopt=64S3,32N2,64N2" \
  --vendor_ramdisk "$W/frags/frag_0_type1_noname.lz4" \
  --ramdisk_type recovery --ramdisk_name recovery \
  --vendor_ramdisk_fragment "$W/recovery_slim.lz4" \
  --vendor_boot "$OUT"
truncate -s 67108864 "$OUT"
ls -lh "$OUT"
sha256sum "$OUT"

echo '--- retained core files ---'
ls -l "$W/root/system/bin/init" "$W/root/system/bin/recovery" \
      "$W/root/lib/modules/focaltech_0flash_mmi_v3.ko" \
      "$W/root/lib/modules/dsi-panel-mot-vdo-txd-ft8725-1080-2388-dphy-fhd-120hz.ko"
echo '--- removed files (expect no output) ---'
ls "$W/root/twres/fonts/wqy-microhei.ttf" "$W/root/vendor/firmware/haptic_nv_rtp.bin" 2>&1 || true
echo '--- module count ---'
ls "$W/root/lib/modules"/*.ko | wc -l

python3 "$ROOT/scripts/verify_built.py" "$OUT" "$STOCK"
