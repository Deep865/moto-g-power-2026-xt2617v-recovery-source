#!/bin/bash
set -o pipefail
export PATH=/root/bin:$PATH
exec > >(tee -a /root/fox16_build.log) 2>&1
echo "=== OFOX16 BUILD START $(date -u) ==="

cd /root/fox_16.0
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=vegas26
export FOX_EXTREME_SIZE_REDUCTION=1
export FOX_BUILD_BASH=0
lunch omni_vegas26-bp2a-eng || { echo '=== LUNCH_FAILED ==='; exit 1; }
mka vendorbootimage -j16 || { echo '=== MKA_FAILED ==='; exit 1; }

IMG=out/target/product/vegas26/vendor_boot.img
ls -lh "$IMG"
mkdir -p /mnt/c/Users/Deep/MotoRoot/wsl-build
cp "$IMG" /mnt/c/Users/Deep/MotoRoot/wsl-build/vendor_boot_ofox16.img
sha256sum /mnt/c/Users/Deep/MotoRoot/wsl-build/vendor_boot_ofox16.img
echo "=== BUILD_OK $(date -u) ==="
