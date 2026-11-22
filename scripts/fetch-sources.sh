#!/bin/bash
# Fetch the upstream AOSP/recovery base trees used by this project.
#
# This is the only step that uses upstream Git. Everything we changed is in this
# repository (device tree, scripts, pins, patches, preserved core tarball), so you
# do not need to browse or edit another project.
#
#   ./scripts/fetch-sources.sh
#   RECOVERIES="orangefox" ./scripts/fetch-sources.sh
#
# Disk: ~120 GB free; time: hours on a normal connection. Run on Linux/WSL2.
set -euo pipefail

ROOT=${ROOT:-$HOME/recovery-sources}
RECOVERIES=${RECOVERIES:-"orangefox twrp pbrp"}
JOBS=${JOBS:-8}
mkdir -p "$ROOT"

want() {
  case " $RECOVERIES " in *" $1 "*) return 0;; *) return 1;; esac
}

command -v git >/dev/null || { echo "git is not installed"; exit 1; }
if want twrp || want pbrp; then
  command -v repo >/dev/null || { echo "repo is not installed (see BUILD-ALL.md)"; exit 1; }
fi

if want orangefox; then
  if [ ! -d "$ROOT/ofox-sync/.git" ]; then
    git clone https://gitlab.com/OrangeFox/sync.git "$ROOT/ofox-sync"
  else
    git -C "$ROOT/ofox-sync" pull --ff-only
  fi
  ( cd "$ROOT/ofox-sync" && ./orangefox_sync.sh --branch 12.1 --path "$ROOT/fox_12.1" )
fi

if want twrp; then
  mkdir -p "$ROOT/twrp_12.1"
  cd "$ROOT/twrp_12.1"
  if [ ! -d .repo ]; then
    repo init --depth=1 \
      -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git \
      -b twrp-12.1
  fi
  repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags
fi

if want pbrp; then
  mkdir -p "$ROOT/pbrp_12.1"
  cd "$ROOT/pbrp_12.1"
  if [ ! -d .repo ]; then
    repo init --depth=1 \
      -u https://github.com/PitchBlackRecoveryProject/manifest_pb.git \
      -b android-12.1
  fi
  repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags
fi

cat <<EOF

Sources are in: $ROOT

OrangeFox : $ROOT/fox_12.1
TWRP      : $ROOT/twrp_12.1
PBRP      : $ROOT/pbrp_12.1

Now build from this repo, for example:
  DEVICE_TREE=$(cd "$(dirname "$0")/.." && pwd) \\
  FOX_TREE=$ROOT/fox_12.1 OUT_DIR=$HOME/recovery-images \\
    "\$DEVICE_TREE/scripts/91-build-ofox12-recovery.sh"

Or all three:
  DEVICE_TREE=$(cd "$(dirname "$0")/.." && pwd) \\
  FOX_TREE=$ROOT/fox_12.1 TWRP_TREE=$ROOT/twrp_12.1 PBRP_TREE=$ROOT/pbrp_12.1 \\
  OUT_DIR=$HOME/recovery-images "\$DEVICE_TREE/scripts/build-all-three.sh"
EOF
