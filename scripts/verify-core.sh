#!/bin/bash
# Verify that the pinned OrangeFox 12.1 core still contains the fixes this device
# needs. Called by 91-build-ofox12-recovery.sh after checkout.
set -euo pipefail

FOX_TREE=${1:-${FOX_TREE:-$HOME/fox_12.1}}
CORE=${2:-${FOX_CORE_REV:-8cd9df2b4}}
R="$FOX_TREE/bootable/recovery"

[ -d "$R" ] || { echo "verify-core: missing $R"; exit 1; }

core_full=$(git -C "$R" rev-parse "$CORE")
head_full=$(git -C "$R" rev-parse HEAD)
[ "$core_full" = "$head_full" ] || {
  echo "verify-core: HEAD is $head_full, expected $core_full"; exit 1; }

check() {
  local file=$1 needle=$2 label=$3
  grep -Fq "$needle" "$R/$file" || {
    echo "verify-core: MISSING $label ($file)"; exit 1; }
}

check partition.cpp 'Skipping data backup size calculation until decryption' \
  'data-size scan skip'
check twrpRepacker.cpp 'root = "/dev/block/by-name/"' \
  'alternate block-device path'
check partitionmanager.cpp 'dev = "/dev/block/by-name/"' \
  'alternate block-device path (AVB)'
check data.cpp 'static_cast<unsigned long>(raw_temp / 1000)' \
  'thermal unsigned-wrap fix'
check Android.mk 'external/bzip2/Android.bp' 'bzip2'
check orangefox.mk 'OF_VIBRATION_DEFAULTS' 'vibration defaults'
check gui/theme/portrait_hdpi/pages/universal.xml 'reboot_recovery_btn' \
  'Reboot Recovery action'
check orangefox.mk 'FOX_NO_BLANK_DT2W' 'double-tap-to-wake'

echo "verify-core: OK $(git -C "$R" log -1 --format='%h %s')"
