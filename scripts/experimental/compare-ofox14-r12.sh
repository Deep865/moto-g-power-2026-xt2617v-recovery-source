#!/bin/bash
set -e
ROOT=/mnt/c/Users/Deep/MotoRoot
W=/root/ofox14_compare
rm -rf "$W"
mkdir -p "$W/frags" "$W/rec"
python3 "$ROOT/scripts/extract_frags.py" "$ROOT/wsl-build/vendor_boot_ofox14_src.img" "$W/frags" >/dev/null
lz4 -d "$W/frags/recovery_ramdisk.lz4" "$W/rec.cpio" >/dev/null
( cd "$W/rec" && cpio -idm --no-absolute-filenames < ../rec.cpio >/dev/null 2>&1 )

for d in /root/ofox/rec "$W/rec"; do
  echo "===== $d ====="
  du -sh "$d"
  echo -n 'files: '; find "$d" -type f | wc -l
  echo '-- module dirs --'
  du -sh "$d/lib/modules" "$d/vendor/lib/modules" "$d/vendor_dlkm/lib/modules" 2>/dev/null || true
  echo '-- largest modules --'
  ls -lS "$d/lib/modules" 2>/dev/null | head -16
  echo '-- largest non-module files --'
  find "$d" -path '*/lib/modules' -prune -o -type f -printf '%s %p\n' | sort -rn | head -20
  echo '-- key files --'
  ls -l "$d/twres/fonts/wqy-microhei.ttf" "$d/system/bin/recovery" "$d/system/bin/init" "$d/sbin/bash" 2>&1 || true
  echo '-- focaltech / panel --'
  ls -l "$d/lib/modules/focaltech_0flash_mmi_v3.ko" "$d/vendor/lib/modules/focaltech_0flash_mmi_v3.ko" "$d/vendor_dlkm/lib/modules/focaltech_0flash_mmi_v3.ko" 2>&1 || true
  ls "$d/lib/modules" 2>/dev/null | grep 'dsi-panel' | wc -l
  echo
done

echo '===== file-list diff (R12.0 vs 14.1) ====='
( cd /root/ofox/rec && find . -type f | sort ) > "$W/r12.files"
( cd "$W/rec" && find . -type f | sort ) > "$W/o14.files"
echo '-- only in R12.0 --'
comm -23 "$W/r12.files" "$W/o14.files" | head -40
echo '-- only in 14.1 --'
comm -13 "$W/r12.files" "$W/o14.files" | head -60
