#!/bin/bash
# Build OrangeFox 12.1 (the true R12.0 source control).
set -o pipefail
exec > >(tee -a /root/ofox12_build.log) 2>&1
echo "=== OFOX12 BUILD START $(date -u) ==="

cd /root/fox_12.1
mkdir -p device/motorola
rm -rf device/motorola/vegas26
cp -r /mnt/c/Users/Deep/MotoRoot/device-tree device/motorola/vegas26

# The device tree sets PLATFORM_VERSION(_LAST_STABLE)=16; A12.1 CTS lists need it too.
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
export BUILD_BROKEN_PLUGIN_VALIDATION=true

if lunch omni_vegas26-ap2a-eng; then
  :
elif lunch omni_vegas26-eng; then
  :
else
  echo '=== LUNCH_FAILED ==='
  exit 1
fi

mka vendorbootimage -j16 || { echo '=== MKA_FAILED ==='; exit 1; }

IMG=out/target/product/vegas26/vendor_boot.img
ls -lh "$IMG"
mkdir -p /mnt/c/Users/Deep/MotoRoot/wsl-build
cp "$IMG" /mnt/c/Users/Deep/MotoRoot/wsl-build/vendor_boot_ofox12_src.img
sha256sum "$IMG" /mnt/c/Users/Deep/MotoRoot/wsl-build/vendor_boot_ofox12_src.img
echo "=== BUILD_OK $(date -u) ==="
