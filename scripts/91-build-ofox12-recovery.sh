#!/bin/bash
# OrangeFox R12.0 (12.1 branch) for vegas26, with the 14.1 backports.
set -o pipefail
FOX_TREE=${FOX_TREE:-$HOME/fox_12.1}
DEVICE_TREE=${DEVICE_TREE:-$(cd "$(dirname "$0")/.." && pwd)}
OUT_DIR=${OUT_DIR:-$PWD/out-images}
mkdir -p "$OUT_DIR"
exec > >(tee -a "$OUT_DIR/ofox12-build.log") 2>&1
echo "=== ORANGEFOX 12.1 BUILD $(date -u) ==="

cd "$FOX_TREE" || { echo "missing FOX_TREE=$FOX_TREE"; exit 1; }

# Pin the working image's codebase and apply the two 14.1 backports.
git -C bootable/recovery checkout -q 3fc9e73f
git -C bootable/recovery reset -q --hard 3fc9e73f
for p in "$DEVICE_TREE"/patches/12.1/000*.patch; do
  echo "applying $(basename "$p")"
  git -C bootable/recovery am "$p" || { echo "patch failed"; exit 1; }
done

# OrangeFox always UPX-compresses /sbin and /system/bin; skip it.
UPX=vendor/recovery/OrangeFox_vendor.sh
if ! grep -q FOX_SKIP_UPX "$UPX"; then
  python3 - "$UPX" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old='$upx_bin --lzma $i;'; new='[ "$FOX_SKIP_UPX" = "1" ] || $upx_bin --lzma $i;'
assert s.count(old)==1, s.count(old)
open(p,'w').write(s.replace(old,new))
PY
fi

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
export FOX_BUILD_DEVICE=vegas26
export FOX_EXTREME_SIZE_REDUCTION=0
export FOX_SKIP_UPX=1
export BUILD_BROKEN_PLUGIN_VALIDATION=true

lunch omni_vegas26-eng || { echo 'lunch failed'; exit 1; }
mka vendorbootimage -j16 || { echo 'build failed'; exit 1; }

IMG=out/target/product/vegas26/vendor_boot.img
cp "$IMG" "$OUT_DIR/OrangeFox-R12.0-vegas26.img"
ls -l "$OUT_DIR/OrangeFox-R12.0-vegas26.img"
sha256sum "$OUT_DIR/OrangeFox-R12.0-vegas26.img"
echo "=== DONE $(date -u) ==="
