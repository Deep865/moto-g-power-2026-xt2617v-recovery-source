#!/bin/bash
# Build an A16-stock + TWRP-14.1 hybrid vendor_boot.
# Base: stock vendor ramdisk (init, ueventd, modules, SELinux).
# Layer: TWRP recovery binary, unique libs, twres, fstab, flags.
set -e
ROOT=/mnt/c/Users/<you>/MotoRoot
W=/root/hybrid
OUT=$ROOT/wsl-build
M=$W/merged
export PATH=/root/twrp/out/host/linux-x86/bin:$PATH
export LC_ALL=C

rm -rf "$M"
cp -a "$W/stock/." "$M/"

# Swap in TWRP's recovery binary (stock init.rc already starts it).
cp -a "$W/twrp/system/bin/recovery" "$M/system/bin/recovery"
chmod 755 "$M/system/bin/recovery"

# Copy only TWRP-only libs in the recovery binary's NEEDED closure.
declare -A seen
queue=("system/bin/recovery")
while [ ${#queue[@]} -gt 0 ]; do
  f="${queue[0]}"; queue=("${queue[@]:1}")
  [ -n "${seen[$f]}" ] && continue
  seen[$f]=1
  p="$W/twrp/$f"; [ -f "$p" ] || p="$W/stock/$f"; [ -f "$p" ] || continue
  while read -r lib; do
    [ -z "$lib" ] && continue
    if [ -f "$W/twrp/system/lib64/$lib" ] && [ ! -f "$W/stock/system/lib64/$lib" ]; then
      queue+=("system/lib64/$lib")
    fi
  done < <(readelf -d "$p" 2>/dev/null | awk '/NEEDED/{gsub(/[\[\]]/,"",$NF); print $NF}' | grep '^lib')
done
for f in "${!seen[@]}"; do
  case "$f" in
    system/lib64/*) cp -a "$W/twrp/$f" "$M/$f" ;;
  esac
done

# TWRP theme.
rm -rf "$M/twres"
cp -a "$W/twrp/twres" "$M/twres"

# TWRP runtime files.
for f in system/etc/recovery.fstab system/etc/twrp.flags \
         system/bin/load_spl.sh system/bin/prepdecrypt.sh system/bin/mtk_plpath_utils; do
  [ -e "$W/twrp/$f" ] && cp -a "$W/twrp/$f" "$M/$f"
done

# TWRP vintf only. Do NOT copy TWRP's system/etc/init/hw/init.rc:
# stock A16 init.rc already starts /system/bin/recovery.
if [ -d "$W/twrp/system/etc/vintf" ]; then
  mkdir -p "$M/system/etc/vintf"
  cp -a "$W/twrp/system/etc/vintf/." "$M/system/etc/vintf/"
fi

# USB/adbd rc used by TWRP, imported from stock init.rc.
if [ -f "$W/twrp/init.recovery.usb.rc" ]; then
  cp -a "$W/twrp/init.recovery.usb.rc" "$M/init.recovery.usb.rc"
  grep -q 'import /init.recovery.usb.rc' "$M/system/etc/init/hw/init.rc" || \
    sed -i '1i import /init.recovery.usb.rc' "$M/system/etc/init/hw/init.rc"
fi

# Repack the merged tree as a single LZ4-legacy ramdisk.
cd "$M"
find . | cpio -o -H newc --owner=0:0 2>/dev/null | lz4 -l -12 > "$W/hybrid_ramdisk.lz4"
ls -lh "$W/hybrid_ramdisk.lz4"

RSIZE=$(stat -c%s "$W/hybrid_ramdisk.lz4")
if [ "$RSIZE" -gt 65536000 ]; then
  echo "ERROR: hybrid ramdisk is $RSIZE bytes, too large for the 64 MiB partition"
  exit 1
fi

# Build the single-platform vendor_boot with the verified geometry.
cd /root/twrp
mkbootimg --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
  --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
  --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
  --dtb device/motorola/vegas26/prebuilt/dtb.img \
  --vendor_cmdline "bootopt=64S3,32N2,64N2" \
  --vendor_ramdisk "$W/hybrid_ramdisk.lz4" \
  --vendor_boot "$OUT/vendor_boot_14_hybrid.img"

ls -lh "$OUT/vendor_boot_14_hybrid.img"
truncate -s 67108864 "$OUT/vendor_boot_14_hybrid.img"
sha256sum "$OUT/vendor_boot_14_hybrid.img"
python3 "$ROOT/scripts/verify_built.py" "$OUT/vendor_boot_14_hybrid.img" "$ROOT/revert/vendor_boot_a.img"
