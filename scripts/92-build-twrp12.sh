#!/bin/bash
# TWRP 3.7.1-12 for vegas26 from the minimal TWRP 12.1 manifest.
set -o pipefail
TWRP_TREE=${TWRP_TREE:-$HOME/twrp_12.1}
DEVICE_TREE=${DEVICE_TREE:-$(cd "$(dirname "$0")/.." && pwd)}
OUT_DIR=${OUT_DIR:-$PWD/out-images}
mkdir -p "$OUT_DIR"
exec > >(tee -a "$OUT_DIR/twrp12-build.log") 2>&1
echo "=== TWRP 12.1 BUILD $(date -u) ==="

cd "$TWRP_TREE" || { echo "missing TWRP_TREE=$TWRP_TREE"; exit 1; }
mkdir -p device/motorola
rm -rf device/motorola/vegas26
rsync -a --exclude .git "$DEVICE_TREE"/ device/motorola/vegas26/
HW=device/motorola/vegas26/recovery/root/vendor/lib64/hw
ln -sfn libMcGatekeeper.so "$HW/gatekeeper.trustonic.so"
ln -sfn libSoftGatekeeper.so "$HW/gatekeeper.default.so"

CTS_ASSETS=cts/tests/tests/os/assets
for f in platform_releases.txt platform_versions.txt; do
  [ -f "$CTS_ASSETS/$f" ] || continue
  grep -qx '16' "$CTS_ASSETS/$f" || echo '16' >> "$CTS_ASSETS/$f"
done

rm -rf out/target/product/vegas26
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export BUILD_BROKEN_PLUGIN_VALIDATION=true

lunch twrp_vegas26-eng || { echo 'lunch failed'; exit 1; }
mka vendorbootimage -j16 || { echo 'build failed'; exit 1; }

IMG=out/target/product/vegas26/vendor_boot.img
cp "$IMG" "$OUT_DIR/TWRP-3.7.1-12-vegas26.img"
ls -l "$OUT_DIR/TWRP-3.7.1-12-vegas26.img"
sha256sum "$OUT_DIR/TWRP-3.7.1-12-vegas26.img"
echo "=== DONE $(date -u) ==="
