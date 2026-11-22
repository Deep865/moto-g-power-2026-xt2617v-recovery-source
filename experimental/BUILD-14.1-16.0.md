> **Historical / not supported.** These are the 14.1 and 16.0 build notes.
> Both branches fail to reach a usable recovery UI on this phone; see
> [`README.md`](README.md) and [`../experimental/BACKPORT-ROADMAP.md`](BACKPORT-ROADMAP.md).
> The supported 12.1 build guide is [`../BUILD-ALL.md`](../BUILD-ALL.md).

# Build notes

## Host

- WSL2 Ubuntu 22.04 (or native Linux), 24 GB RAM for WSL, 16 jobs. A 16 GB host OOMs
  during Soong analysis on the 14.1 tree.
- `repo`, `git`, `bc bison build-essential ccache curl flex g++-multilib gcc-multilib
  lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5
  libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool
  squashfs-tools xsltproc zip zlib1g-dev python3 python-is-python3 openjdk-17-jdk cpio`.
- Platform-tools 37.0.1 or 35.0.0 on the PC side.

## TWRP 14.1 (builds; userspace does not boot)

```bash
mkdir -p ~/twrp && cd ~/twrp
repo init --depth=1 \
  -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git \
  -b twrp-14.1
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags

cp -r /path/to/device-tree device/motorola/vegas26

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_vegas26-ap2a-eng
mka vendorbootimage -j16
```

`scripts/10-build-14.1.sh` automates this, including the A14 fixes.

### A14 fixes applied after each sync

| Problem | Fix |
|---|---|
| `envsetup.sh: TOP: unbound variable` | run without `set -u` (`set -eo pipefail`) |
| CTS rejects `PLATFORM_VERSION := 16` | append `16` to `cts/tests/tests/os/assets/platform_releases.txt` and `platform_versions.txt` |
| `-ndk_platform` module names gone | `sed -i 's/-ndk_platform/-ndk/g'` in `bootable/recovery/Android.mk` and `libtar/Android.mk` |
| libtar fscrypt helpers missing | `TW_INCLUDE_CRYPTO_FBE := false` in `bootable/recovery/Android.mk` (libtar only) |
| removed FDE helpers | stub `cryptfs_check_passwd`, `cryptfs_get_password_type`, `cryptfs_check_footer`, `set_partition_data`, `delete_crypto_blk_dev` |
| `fscrypt_policy` macro in C++ | `struct fscrypt_policy *fep;` in `libtar/libtar.h` |
| bootctrl HAL missing `android::base` | add `libbase` to `bootctrl/Android.bp` |
| recovery link missing `crypto_scrypt` | add `libscrypt_static` to recovery static libs |

### Repack and verify

The A14 build emits a type-2 `recovery` fragment. This bootloader uses the `platform`
fragment, so repack:

```bash
python3 scripts/extract_frags.py out/target/product/vegas26/vendor_boot.img /tmp/frags
mkbootimg --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
  --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
  --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
  --dtb device/motorola/vegas26/prebuilt/dtb.img \
  --vendor_cmdline "bootopt=64S3,32N2,64N2" \
  --vendor_ramdisk /tmp/frags/recovery_ramdisk.lz4 \
  --vendor_boot vendor_boot_platform.img
truncate -s 67108864 vendor_boot_platform.img
python3 scripts/verify_built.py vendor_boot_platform.img revert/vendor_boot_a.img
```

Expected: VNDRBOOT, hdr 4, page 4096, kernel `0x40000000`, ramdisk `0x66f00000`,
DTB `183530` / SHA `50cf2684…`, ≤ 67,108,864, single platform fragment.

## OrangeFox 16.0 (source)

```bash
mkdir -p ~/ofox-sync && cd ~/ofox-sync
git clone https://gitlab.com/OrangeFox/sync.git
cd sync
./orangefox_sync.sh --branch 16.0 --path /root/fox_16.0

cp -r /path/to/device-tree /root/fox_16.0/device/motorola/vegas26
cd /root/fox_16.0
source build/envsetup.sh
lunch twrp_vegas26-bp2a-eng        # confirm the combo after sync
mka vendorbootimage -j16           # or recoveryimage if the tree expects it
```

The 16.0 manifest owns the OrangeFox recovery and `vendor/recovery`; the product
makefile may need to inherit the OrangeFox common config instead of `vendor/twrp`.
Bring-up status is tracked in `STATUS.md`.

### A16 build fixes found on this tree

- `device.mk`: `PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := false`
  The bundled `magiskboot` prebuilt is 4K-page aligned; A16’s prebuilt ELF check wants
  16K and stops at 96% with `Load segment has alignment 4096 but 16384 required`.
- `BoardConfig.mk`: `TW_EXCLUDE_NANO := true`
  OrangeFox post-processing removes `system/etc/terminfo` while the `nano_twrp` rule
  copies it; the parallel copy fails at 67% with `cp: …/terminfo/… No such file or
  directory`. Nano is optional; excluding it removes the race.

### 16.0 result

The 16.0 build compiles and verifies, but the image is not a working recovery: the
16.0-built platform fails at the bootloader, and the 16.0 recovery on the R12.0 platform
only reaches the splash. Full results/hashes are in the docs repo `docs/05-ofox16.md`.

## OrangeFox 14.1 source

```bash
./orangefox_sync.sh --branch 14.1 --path /root/fox_14.1
# repo may hit AOSP Gitiles HTTP 429; retry with -j4:
cd /root/fox_14.1 && repo sync -c -j4 --force-sync --no-clone-bundle --no-tags
```

The 14.1 build uses the A14 TWRP device tree (`/root/twrp/device/motorola/vegas26`) and
is a newer control. The working image is **OrangeFox R12.0**; the true source control is
the 12.1 branch.

## OrangeFox 12.1 source (working)

Verified 2026-11-22. This reproduces the XDA R12.0 image from source.

```bash
./orangefox_sync.sh --branch 12.1 --path /root/fox_12.1
# copy this tree to /root/fox_12.1/device/motorola/vegas26 (the script does it)
scripts/90-build-ofox12-source.sh
```

Traps fixed by the script:

| Symptom | Cause | Fix |
|---|---|---|
| black screen / bootloop | OrangeFox UPX-compresses `init`, `recovery`, `adbd`, `sh` in `/sbin` and `/system/bin` | `FOX_SKIP_UPX=1` (the script patches `vendor/recovery/OrangeFox_vendor.sh`) |
| hangs after the OrangeFox splash | `prepdecrypt.sh` had a Windows CRLF shebang (`#!/sbin/sh\r`) -> status 127 -> `crypto.ready` never set -> Trustonic KeyMint never starts -> `keystore2` aborts -> TWRP waits forever | keep every device-tree text file LF |
| decrypt hangs at `using secdis to decrypt spblob` | `vendor/lib64/hw/gatekeeper.{trustonic,default}.so` were 18/20-byte text files instead of symlinks | link them to `libMcGatekeeper.so` / `libSoftGatekeeper.so` |
| TWRP partition scan / hang | stock fstab with duplicate erofs/ext4 entries and `first_stage_mount` | use the minimal working `recovery.fstab` |
| small UI differences | newer `bootable/recovery` | pin to `3fc9e73f` (2026-08-21) |

The script also sets `FOX_EXTREME_SIZE_REDUCTION=0`, so fonts, FFiles and bash stay.
Output is a two-fragment `vendor_boot` (~55.5 MB of content), well under the 64 MB
partition.

## Known-good binary

The **OrangeFox R12.0** image with the stock FT8725 module is documented in the docs repo
(`https://github.com/Deep865/moto-g-power-2026-xt2617v-walmart-recovery`), including the exact repack script and
SHA-256. Use it as the fallback while the 14.1/16.0 source builds are brought up.
