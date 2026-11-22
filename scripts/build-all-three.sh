#!/bin/bash
# Build one, two or all three working recoveries from the same device tree.
#
#   DEVICE_TREE=... FOX_TREE=... TWRP_TREE=... PBRP_TREE=... OUT_DIR=... \
#     ./build-all-three.sh
#
# Build a subset with RECOVERIES="orangefox twrp" (space separated).
set -euo pipefail

DEVICE_TREE=${DEVICE_TREE:-$(cd "$(dirname "$0")/.." && pwd)}
OUT_DIR=${OUT_DIR:-$PWD/out-images}
RECOVERIES=${RECOVERIES:-"orangefox twrp pbrp"}

mkdir -p "$OUT_DIR"
echo "device tree : $DEVICE_TREE"
echo "output      : $OUT_DIR"
echo "recoveries  : $RECOVERIES"
echo

want() {
  case " $RECOVERIES " in *" $1 "*) return 0;; *) return 1;; esac
}

if want orangefox; then
  : "${FOX_TREE:?set FOX_TREE to the OrangeFox 12.1 checkout}"
  [ -d "$FOX_TREE/.repo" ] || [ -d "$FOX_TREE/build" ] || {
    echo "FOX_TREE=$FOX_TREE does not look like a synced OrangeFox tree"; exit 1; }
  echo "=== OrangeFox R12.0 ==="
  FOX_TREE="$FOX_TREE" DEVICE_TREE="$DEVICE_TREE" OUT_DIR="$OUT_DIR" \
    "$DEVICE_TREE/scripts/91-build-ofox12-recovery.sh"
fi

if want twrp; then
  : "${TWRP_TREE:?set TWRP_TREE to the TWRP 12.1 checkout}"
  [ -d "$TWRP_TREE/.repo" ] || [ -d "$TWRP_TREE/build" ] || {
    echo "TWRP_TREE=$TWRP_TREE does not look like a synced TWRP tree"; exit 1; }
  echo "=== TWRP 3.7.1-12 ==="
  TWRP_TREE="$TWRP_TREE" DEVICE_TREE="$DEVICE_TREE" OUT_DIR="$OUT_DIR" \
    "$DEVICE_TREE/scripts/92-build-twrp12.sh"
fi

if want pbrp; then
  : "${PBRP_TREE:?set PBRP_TREE to the PBRP 12.1 checkout}"
  [ -d "$PBRP_TREE/vendor/pb" ] || {
    echo "PBRP_TREE=$PBRP_TREE is missing vendor/pb"; exit 1; }
  echo "=== PBRP 4.x ==="
  PBRP_TREE="$PBRP_TREE" DEVICE_TREE="$DEVICE_TREE" OUT_DIR="$OUT_DIR" \
    "$DEVICE_TREE/scripts/93-build-pbrp12.sh"
fi

echo
echo "=== images ==="
for f in "$OUT_DIR"/OrangeFox-R12.0-vegas26.img \
         "$OUT_DIR"/TWRP-3.7.1-12-vegas26.img \
         "$OUT_DIR"/PBRP-4.x-vegas26.img; do
  [ -f "$f" ] && { stat -c '%n %s bytes' "$f"; sha256sum "$f"; }
done
