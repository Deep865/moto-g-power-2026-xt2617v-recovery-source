#!/bin/bash
# Build OrangeFox 14.1 from the synced fox_14.1 tree.
# The working image is OrangeFox R12.0; this 14.1 build is the newer control.
set -eo pipefail
exec > >(tee -a /root/ofox14_build.log) 2>&1
echo "=== OFOX14 BUILD START $(date -u) ==="

cd /root/fox_14.1

# Use the A14 TWRP device tree; the Windows device-tree is the A16 fixed copy.
mkdir -p device/motorola
rm -rf device/motorola/vegas26
cp -r /root/twrp/device/motorola/vegas26 device/motorola/vegas26

# AOSP 14's CTS asset lists do not know Android 16, but the device tree sets
# PLATFORM_VERSION(_LAST_STABLE)=16.
CTS_ASSETS=cts/tests/tests/os/assets
for f in platform_releases.txt platform_versions.txt; do
  [ -f "$CTS_ASSETS/$f" ] || continue
  grep -qx '16' "$CTS_ASSETS/$f" || echo '16' >> "$CTS_ASSETS/$f"
done

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=vegas26
export FOX_EXTREME_SIZE_REDUCTION=1
export FOX_BUILD_BASH=0
# AOSP 14 Soong rejects the OrangeFox/TWRP recovery Soong plugins unless this is set.
export BUILD_BROKEN_PLUGIN_VALIDATION=true

if lunch omni_vegas26-ap2a-eng; then
  :
elif lunch twrp_vegas26-ap2a-eng; then
  :
else
  echo '=== LUNCH_FAILED ==='
  exit 1
fi

mka vendorbootimage -j16 || { echo '=== MKA_FAILED ==='; exit 1; }

IMG=out/target/product/vegas26/vendor_boot.img
ls -lh "$IMG"
mkdir -p /mnt/c/Users/Deep/MotoRoot/wsl-build
cp "$IMG" /mnt/c/Users/Deep/MotoRoot/wsl-build/vendor_boot_ofox14_src.img
sha256sum "$IMG" /mnt/c/Users/Deep/MotoRoot/wsl-build/vendor_boot_ofox14_src.img
echo "=== BUILD_OK $(date -u) ==="
