#!/bin/bash
# Bake the stock (working) focaltech FT8725 module into the OrangeFox image
# and rebuild the same two-fragment vendor_boot layout.
set -e
ROOT=/mnt/c/Users/<you>/MotoRoot
W=/root/ofox
OUT=$ROOT/wsl-build
export PATH=/root/twrp/out/host/linux-x86/bin:$PATH
export LC_ALL=C

# Remove the extracted archive so it is not packed back into the ramdisk.
rm -f "$W/rec/rec.cpio" "$W/plat/plat.cpio"

# Replace both copies of the focaltech module with the stock one that binds.
cp -f "$ROOT/downloads/stock_focaltech.ko" "$W/rec/vendor/lib/modules/focaltech_0flash_mmi_v3.ko"
cp -f "$ROOT/downloads/stock_focaltech.ko" "$W/rec/vendor_dlkm/lib/modules/focaltech_0flash_mmi_v3.ko"
chmod 644 "$W/rec/vendor/lib/modules/focaltech_0flash_mmi_v3.ko" "$W/rec/vendor_dlkm/lib/modules/focaltech_0flash_mmi_v3.ko"
ls -l "$W/rec/vendor/lib/modules/focaltech_0flash_mmi_v3.ko" "$W/rec/vendor_dlkm/lib/modules/focaltech_0flash_mmi_v3.ko"

# Repack the recovery ramdisk.
cd "$W/rec"
find . | cpio -o -H newc --owner=0:0 2>/dev/null | lz4 -l -12 > "$W/recovery_new.lz4"
ls -lh "$W/recovery_new.lz4"
RSIZE=$(stat -c%s "$W/recovery_new.lz4")
if [ "$RSIZE" -gt 64000000 ]; then echo "ERROR: ramdisk too big: $RSIZE"; exit 1; fi

# Rebuild the exact two-fragment layout: platform (original) + recovery (patched).
mkbootimg --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
  --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
  --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
  --dtb /root/twrp/device/motorola/vegas26/prebuilt/dtb.img \
  --vendor_cmdline "bootopt=64S3,32N2,64N2" \
  --vendor_ramdisk "$W/frags/frag_0_type1_noname.lz4" \
  --ramdisk_type recovery --ramdisk_name recovery \
  --vendor_ramdisk_fragment "$W/recovery_new.lz4" \
  --vendor_boot "$OUT/vegas_ofox_fixed.img"

truncate -s 67108864 "$OUT/vegas_ofox_fixed.img"
ls -lh "$OUT/vegas_ofox_fixed.img"
sha256sum "$OUT/vegas_ofox_fixed.img"
python3 "$ROOT/scripts/verify_built.py" "$OUT/vegas_ofox_fixed.img" "$ROOT/revert/vendor_boot_a.img"
