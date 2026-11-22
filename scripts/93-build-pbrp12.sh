#!/bin/bash
# PBRP 4.x (android-12.1) for vegas26 from manifest_pb.
set -o pipefail
PBRP_TREE=${PBRP_TREE:-$HOME/pbrp_12.1}
DEVICE_TREE=${DEVICE_TREE:-$(cd "$(dirname "$0")/.." && pwd)}
OUT_DIR=${OUT_DIR:-$PWD/out-images}
mkdir -p "$OUT_DIR"
exec > >(tee -a "$OUT_DIR/pbrp12-build.log") 2>&1
echo "=== PBRP 12.1 BUILD $(date -u) ==="

cd "$PBRP_TREE" || { echo "missing PBRP_TREE=$PBRP_TREE"; exit 1; }
[ -d vendor/pb ] || { echo "sync PBRP first (vendor/pb missing)"; exit 1; }

mkdir -p device/motorola
rm -rf device/motorola/vegas26
rsync -a --exclude .git "$DEVICE_TREE"/ device/motorola/vegas26/
HW=device/motorola/vegas26/recovery/root/vendor/lib64/hw
ln -sfn libMcGatekeeper.so "$HW/gatekeeper.trustonic.so"
ln -sfn libSoftGatekeeper.so "$HW/gatekeeper.default.so"

# PBRP product inherits vendor/pb, not vendor/twrp.
sed 's|vendor/twrp/config/common.mk|vendor/pb/config/common.mk|; s|PRODUCT_NAME := twrp_vegas26|PRODUCT_NAME := pb_vegas26|' \
  device/motorola/vegas26/twrp_vegas26.mk > device/motorola/vegas26/pb_vegas26.mk
printf '\nPRODUCT_MAKEFILES += $(LOCAL_DIR)/pb_vegas26.mk\nCOMMON_LUNCH_CHOICES += pb_vegas26-eng\n' \
  >> device/motorola/vegas26/AndroidProducts.mk

CTS_ASSETS=cts/tests/tests/os/assets
for f in platform_releases.txt platform_versions.txt; do
  [ -f "$CTS_ASSETS/$f" ] || continue
  grep -qx '16' "$CTS_ASSETS/$f" || echo '16' >> "$CTS_ASSETS/$f"
done

rm -rf out/target/product/vegas26
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export BUILD_BROKEN_PLUGIN_VALIDATION=true

lunch pb_vegas26-eng || { echo 'lunch failed'; exit 1; }
mka vendorbootimage -j16 || { echo 'build failed'; exit 1; }

IMG=out/target/product/vegas26/vendor_boot.img
cp "$IMG" "$OUT_DIR/PBRP-4.x-vegas26.img"
ls -l "$OUT_DIR/PBRP-4.x-vegas26.img"
sha256sum "$OUT_DIR/PBRP-4.x-vegas26.img"
echo "=== DONE $(date -u) ==="
