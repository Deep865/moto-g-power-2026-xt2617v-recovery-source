#!/bin/bash
# OrangeFox R12.0 (latest fox_12.1 core) for vegas26.
set -o pipefail
FOX_TREE=${FOX_TREE:-$HOME/fox_12.1}
FOX_CORE_REV=${FOX_CORE_REV:-8cd9df2b4}
DEVICE_TREE=${DEVICE_TREE:-$(cd "$(dirname "$0")/.." && pwd)}
OUT_DIR=${OUT_DIR:-$PWD/out-images}
mkdir -p "$OUT_DIR"
case "$OUT_DIR" in
  /mnt/*) echo "OUT_DIR must be on a case-sensitive Linux filesystem, not /mnt/*"; exit 1;;
esac
exec > >(tee -a "$OUT_DIR/ofox12-build.log") 2>&1
echo "=== ORANGEFOX 12.1 BUILD $(date -u) ==="

cd "$FOX_TREE" || { echo "missing FOX_TREE=$FOX_TREE"; exit 1; }

# Pin to the newer fox_12.1 core. It includes the two former 14.1 backports
# (skip data-size scan before decrypt; alternate /dev/block/by-name fallbacks)
# plus thermal, bzip2, vibration, reboot-recovery and dt2w fixes.
git -C bootable/recovery fetch -q origin fox_12.1 2>/dev/null || true
git -C bootable/recovery checkout -q "$FOX_CORE_REV"
git -C bootable/recovery reset -q --hard "$FOX_CORE_REV"
echo "OrangeFox recovery core: $(git -C bootable/recovery log -1 --format='%h %s')"
bash "$DEVICE_TREE/scripts/verify-core.sh" "$FOX_TREE" "$FOX_CORE_REV" || {
  echo "verify-core failed; refusing to build"; exit 1; }

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

IMG="$OUT_DIR/target/product/vegas26/vendor_boot.img"
[ -f "$IMG" ] || IMG="$OUT_DIR/target/product/vegas26/OrangeFox-R12.0-Unofficial-vegas26.img"
cp "$IMG" "$OUT_DIR/OrangeFox-R12.0-vegas26.img"
ls -l "$OUT_DIR/OrangeFox-R12.0-vegas26.img"
sha256sum "$OUT_DIR/OrangeFox-R12.0-vegas26.img"
echo "=== DONE $(date -u) ==="
