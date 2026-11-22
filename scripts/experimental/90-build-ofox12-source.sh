#!/bin/bash
# Reproduce the working OrangeFox R12.0 (12.1 branch) from source.
#
# Verified 2026-11-22 on XT2617V: boots to the UI, touch works, FBE /data
# decrypts, backup works. This is the same source tree and codebase as the
# XDA prebuilt, with the three Windows/OrangeFox traps fixed:
#   1. UPX is skipped (OrangeFox compresses /sbin and /system/bin; the
#      compressed init/recovery never reached the UI on this device).
#   2. bootable/recovery is pinned to 3fc9e73f (2026-08-21), the codebase
#      recorded in the working image.
#   3. Text files are LF and the two gatekeeper HAL aliases are real
#      symlinks, not Windows-flattened text files.
set -o pipefail
exec > >(tee -a /root/ofox12_source.log) 2>&1
echo "=== OFOX12 SOURCE BUILD START $(date -u) ==="

FOX=/root/fox_12.1
REPO=/root/vegas26-twrp-repo
DT="$REPO"
[ -d "$DT" ] || DT=/mnt/c/Users/Deep/MotoRoot/device-tree

cd "$FOX"

# 1) exact codebase of the working image
git -C bootable/recovery checkout --quiet 3fc9e73f || { echo '=== CHECKOUT_FAILED ==='; exit 1; }
echo "bootable/recovery: $(git -C bootable/recovery rev-parse --short HEAD) $(git -C bootable/recovery log -1 --format=%cd --date=short)"

# 2) make OrangeFox skip UPX compression (idempotent)
UPX=vendor/recovery/OrangeFox_vendor.sh
if ! grep -q FOX_SKIP_UPX "$UPX"; then
  python3 - <<'PYEOF'
p='/root/fox_12.1/vendor/recovery/OrangeFox_vendor.sh'
s=open(p).read()
old='$upx_bin --lzma $i;'
new='[ "$FOX_SKIP_UPX" = "1" ] || $upx_bin --lzma $i;'
assert s.count(old)==1, ('unexpected upx matches', s.count(old))
open(p,'w').write(s.replace(old,new))
print('patched UPX line')
PYEOF
fi
echo "UPX skip patch: $(grep -c FOX_SKIP_UPX "$UPX")"

# 3) device tree (prefer this repo over the Windows working copy)
rm -rf device/motorola/vegas26
rsync -a --exclude .git "$DT"/ device/motorola/vegas26/

# 4) the two gatekeeper aliases must be symlinks, never 18/20-byte text files
HW=device/motorola/vegas26/recovery/root/vendor/lib64/hw
ln -sfn libMcGatekeeper.so "$HW/gatekeeper.trustonic.so"
ln -sfn libSoftGatekeeper.so "$HW/gatekeeper.default.so"
ls -l "$HW/gatekeeper.trustonic.so" "$HW/gatekeeper.default.so"

# 5) A12.1 CTS asset lists must accept PLATFORM_VERSION 16
CTS_ASSETS=cts/tests/tests/os/assets
for f in platform_releases.txt platform_versions.txt; do
  [ -f "$CTS_ASSETS/$f" ] || continue
  grep -qx '16' "$CTS_ASSETS/$f" || echo '16' >> "$CTS_ASSETS/$f"
done

rm -rf out/target/product/vegas26

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=vegas26
export FOX_EXTREME_SIZE_REDUCTION=0
export FOX_SKIP_UPX=1
export BUILD_BROKEN_PLUGIN_VALIDATION=true

lunch omni_vegas26-eng || { echo '=== LUNCH_FAILED ==='; exit 1; }
mka vendorbootimage -j16 || { echo '=== MKA_FAILED ==='; exit 1; }

IMG=out/target/product/vegas26/vendor_boot.img
R=out/target/product/vegas26/recovery/root
mkdir -p /mnt/c/Users/Deep/MotoRoot/wsl-build
cp "$IMG" /mnt/c/Users/Deep/MotoRoot/wsl-build/vendor_boot_ofox12_source.img

echo
echo "=== RESULT ==="
ls -l "$IMG"
sha256sum "$IMG" /mnt/c/Users/Deep/MotoRoot/wsl-build/vendor_boot_ofox12_source.img
echo "codebase: $(grep -E '^ro.build.fox_codebase=' "$R/prop.default")"
file "$R/system/bin/prepdecrypt.sh"
echo "fstab=$(stat -c%s "$R/system/etc/recovery.fstab")  init=$(stat -c%s "$R/system/bin/init")  recovery=$(stat -c%s "$R/system/bin/recovery")"
echo "modules: lib=$(ls "$R"/lib/modules/*.ko 2>/dev/null | wc -l) vendor=$(ls "$R"/vendor/lib/modules/*.ko 2>/dev/null | wc -l) vendor_dlkm=$(ls "$R"/vendor_dlkm/lib/modules/*.ko 2>/dev/null | wc -l)"
python3 scripts/extract_frags.py "$IMG" /tmp/source_frags 2>/dev/null | tail -4
echo "=== BUILD_OK $(date -u) ==="
