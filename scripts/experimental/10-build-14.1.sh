#!/bin/bash
# Build TWRP vendor_boot for vegas26 from the minimal TWRP 14.1 manifest.
# Run INSIDE WSL Ubuntu 22.04 as root:  bash /path/to/10-build-14.1.sh
set -eo pipefail
export LC_ALL=C
exec > >(tee -a /root/build14.log) 2>&1

echo "=== START $(date -u) ==="
df -h /

export DEBIAN_FRONTEND=noninteractive
apt-get update

CORE="bc bison build-essential curl flex git gnupg gperf imagemagick liblz4-tool \
libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools \
xsltproc zip zlib1g-dev python3 python-is-python3 openjdk-17-jdk cpio unzip file"
EXTRA="g++-multilib gcc-multilib lib32ncurses5-dev lib32readline-dev lib32z1-dev \
libncurses5 libncurses5-dev libsdl1.2-dev"

# shellcheck disable=SC2086
if ! apt-get install -y --no-install-recommends $CORE $EXTRA; then
  echo "=== EXTRA 32-bit deps failed; retrying with core set only ==="
  # shellcheck disable=SC2086
  apt-get install -y --no-install-recommends $CORE
fi

git config --global user.name "vegas26 builder"
git config --global user.email "builder@localhost"
git config --global color.ui false

mkdir -p /root/bin
curl -s https://storage.googleapis.com/git-repo-downloads/repo -o /root/bin/repo
chmod a+x /root/bin/repo
export PATH=/root/bin:$PATH

mkdir -p /root/twrp
cd /root/twrp
if [ ! -d .repo ]; then
  repo init --depth=1 \
    -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git \
    -b twrp-14.1
fi

echo "=== disk before sync ==="; df -h /
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
echo "=== disk after sync ==="; df -h /
du -sh .repo . 2>/dev/null | tail -2 || true

# AOSP 14's CTS asset lists do not know Android 16. The device tree sets
# PLATFORM_VERSION(_LAST_STABLE)=16 for anti-rollback, so extend the lists
# after every sync (repo may restore them).
CTS_ASSETS=cts/tests/tests/os/assets
for f in platform_releases.txt platform_versions.txt; do
  [ -f "$CTS_ASSETS/$f" ] || continue
  grep -qx '16' "$CTS_ASSETS/$f" || echo '16' >> "$CTS_ASSETS/$f"
done

# TWRP 14.1 still references A12-era AIDL NDK module names. AOSP 14 ships
# the "-ndk" variants (the "-ndk_platform" ones no longer exist for apc,
# authorization and maintenance). repo sync restores these files.
for f in bootable/recovery/Android.mk bootable/recovery/libtar/Android.mk; do
  [ -f "$f" ] && sed -i 's/-ndk_platform/-ndk/g' "$f"
done

# AOSP 14's system/vold no longer provides the fscrypt helpers that TWRP's
# libtar calls (get_policy, get_policy_descriptor, ...). Keep FBE out of
# libtar only; the main recovery still builds with TW_INCLUDE_CRYPTO.
if [ -f bootable/recovery/Android.mk ]; then
  sed -i 's/^\( *\)TW_INCLUDE_CRYPTO_FBE := true/\1TW_INCLUDE_CRYPTO_FBE := false/' bootable/recovery/Android.mk
fi

# AOSP 14 vold removed cryptfs_check_passwd (FDE). This device is FBE-only;
# the FBE branch above is untouched, so stub the FDE fallback call.
if [ -f bootable/recovery/partitionmanager.cpp ]; then
  sed -i 's/int ret = cryptfs_check_passwd(cPassword);/int ret = -1; \/\/ cryptfs_check_passwd removed in AOSP 14 (FDE not supported)/' bootable/recovery/partitionmanager.cpp
fi

# Same for the FDE password-type helper; -1 means "unknown", FDE path only.
for f in bootable/recovery/partitionmanager.cpp bootable/recovery/partition.cpp; do
  [ -f "$f" ] && sed -i 's/cryptfs_get_password_type()/(-1)/g' "$f"
done

# FDE footer check also removed; an FBE device has no FDE footer, so return -1.
if [ -f bootable/recovery/partition.cpp ]; then
  sed -i 's/cryptfs_check_footer()/(-1)/g' bootable/recovery/partition.cpp
fi

# bionic 14 defines fscrypt_policy as a macro to fscrypt_policy_v1; C++ needs
# the struct tag in libtar.h.
if [ -f bootable/recovery/libtar/libtar.h ]; then
  sed -i 's|fscrypt_policy  \*fep;|struct fscrypt_policy *fep;|' bootable/recovery/libtar/libtar.h
fi

# More removed FDE helpers in partition.cpp (dead on FBE-only devices).
if [ -f bootable/recovery/partition.cpp ]; then
  sed -i 's|^\(\s*\)set_partition_data(.*|\1// set_partition_data removed in AOSP 14 (FDE)|' bootable/recovery/partition.cpp
  sed -i 's|delete_crypto_blk_dev((char\*)("userdata"))|0|' bootable/recovery/partition.cpp
fi

# AOSP 14 libvold references crypto_scrypt; the recovery link needs it.
if [ -f bootable/recovery/Android.mk ]; then
  grep -q 'libscrypt_static' bootable/recovery/Android.mk || \
    sed -i '/LOCAL_STATIC_LIBRARIES += libkeymint_support/a\    LOCAL_STATIC_LIBRARIES += libscrypt_static' bootable/recovery/Android.mk
fi

# Device tree comes from the zip, not from git.
rm -rf device/motorola/vegas26
mkdir -p device/motorola
cp -r /mnt/c/Users/<you>/MotoRoot/device-tree device/motorola/vegas26
find device/motorola/vegas26 -name '*.sh' -exec chmod +x {} \;

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_vegas26-ap2a-eng

echo "=== disk before build ==="; df -h /
mka vendorbootimage -j16

IMG=out/target/product/vegas26/vendor_boot.img
ls -lh "$IMG"
mkdir -p /mnt/c/Users/<you>/MotoRoot/wsl-build
cp "$IMG" /mnt/c/Users/<you>/MotoRoot/wsl-build/vendor_boot_14.img
sha256sum /mnt/c/Users/<you>/MotoRoot/wsl-build/vendor_boot_14.img
echo "=== BUILD_OK $(date -u) ==="
