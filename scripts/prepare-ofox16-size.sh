#!/bin/bash
set -e
T=/root/fox_16.0/device/motorola/vegas26/recovery/root

# Use the known-good working image's module set (207 modules, 28 MB) instead of the
# full stock vendor-ramdisk set (381 modules, 62 MB) that pushed vendor_boot over 64 MiB.
rm -rf "$T/lib/modules"
cp -a /root/ofox/rec/lib/modules "$T/lib/modules"

# Keep the stock FT8725 module in every touch-module path.
for d in lib/modules vendor/lib/modules vendor_dlkm/lib/modules; do
  [ -d "$T/$d" ] && cp -f /mnt/c/Users/Deep/MotoRoot/downloads/stock_focaltech.ko "$T/$d/focaltech_0flash_mmi_v3.ko"
done

echo '--- module counts/sizes ---'
du -sh "$T/lib/modules" "$T/vendor/lib/modules" "$T/vendor_dlkm/lib/modules" 2>/dev/null
ls "$T/lib/modules" | wc -l

# Force the recovery root/ramdisk to be regenerated from the new tree.
rm -rf /root/fox_16.0/out/target/product/vegas26/recovery/root
rm -f /root/fox_16.0/out/target/product/vegas26/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4
rm -f /root/fox_16.0/out/target/product/vegas26/vendor_boot.img
