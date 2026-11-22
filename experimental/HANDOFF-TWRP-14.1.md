# vegas26 TWRP port — build handoff

Everything needed to rebuild and test TWRP for the Moto G Power 2026 (XT2617V / `vegas26`)
on a machine with enough RAM. Written after a full session on a 16 GB laptop, where the
AOSP 14.1 Soong analysis phase could not fit in memory.

## Device

| Item | Value |
|---|---|
| Model / SKU | moto g power - 2026 / XT2617V |
| Codename | `vegas26` (bootloader product `vegas`) |
| SoC | MediaTek MT6835 (Dimensity 6300) |
| Firmware | W1WEOS36.48-22-3-3-4-3, Android 16, patch 2026-06-01 |
| Kernel | 5.15.189-android13-8-00018-g9c82b71884fd-ab14885418 |
| Slot | `_a` |
| Bootloader | unlocked (`flashing_unlocked`), Magisk 31.1 root installed |
| Display | 1080 × 2388, density 390 |

## Current phone state (as of handoff)

- Stock `vendor_boot_a` restored — hash `fbab749b8f66a978569c54189bf20fecff1888791361707f33ef7af6d7b1194b`
- `boot_a`, `init_boot_a` (Magisk-patched), `super`, `seccomp`/calibration partitions untouched
- Magisk 31.1 root working, modules `wifi_ota_guard` + `wifi_carrier_debloat` installed
- All partitions backed up in `C:\Users\Deep\MotoRoot\private-backups` (21 images, 11.27 GB)

## Repo

`git@github.com:Deep865/moto-g-power-2026-xt2617v-walmart-recovery-source.git` (private) — the device tree, ported from
`crabcakes97/moto_G_Play_2026_TWRP` (nevada).

Clone it as `device/motorola/vegas26` inside the AOSP tree:

```bash
git clone git@github.com:Deep865/moto-g-power-2026-xt2617v-walmart-recovery-source.git device/motorola/vegas26
```

## Build on a 32 GB machine

Ubuntu 22.04, ~150 GB free disk (the 14.1 checkout is ~81 GB plus `out/`).

```bash
sudo apt install -y bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
  git git-lfs gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev \
  liblz4-tool libncurses5 libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush \
  rsync schedtool squashfs-tools xsltproc zip zlib1g-dev python3 python-is-python3 \
  openjdk-17-jdk cpio

mkdir -p ~/bin && curl -s https://storage.googleapis.com/git-repo-downloads/repo -o ~/bin/repo
chmod a+x ~/bin/repo && export PATH=~/bin:$PATH

mkdir -p ~/twrp && cd ~/twrp
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-14.1
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags

git clone git@github.com:Deep865/moto-g-power-2026-xt2617v-walmart-recovery-source.git device/motorola/vegas26

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_vegas26-ap2a-eng
mka vendorbootimage -j16
```

Output: `out/target/product/vegas26/vendor_boot.img` (expect ~60 MB, padded/limit 67,108,864 bytes).

## Fixes already applied (do not re-do)

1. `device.mk`: removed `$(call inherit-product, $(SRC_TARGET_DIR)/product/gsi_keys.mk)` — file
   does not exist in AOSP 14.
2. `TARGET_RELEASE` must NOT be in `BoardConfig.mk` (read-only there). Use the lunch combo
   `twrp_vegas26-ap2a-eng`.
3. `BoardConfig.mk`: 32-bit ARM (`TARGET_2ND_ARCH*`) removed to shrink the Soong graph — this is
   why the build needs less RAM. If you have plenty of RAM and want 32-bit support back, restore:
   ```
   TARGET_2ND_ARCH := arm
   TARGET_2ND_ARCH_VARIANT := armv7-a-neon
   TARGET_2ND_CPU_VARIANT := generic
   TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a53
   TARGET_2ND_CPU_ABI := armeabi-v7a
   TARGET_2ND_CPU_ABI2 := armeabi
   ```
4. `BOARD_VENDOR_CMDLINE` is only `bootopt=64S3,32N2,64N2`. mkbootimg 12.1/14.1 rejects unknown
   tokens; the stock cmdline also has `mem.enable_mglru=1 loglevel=4 initcall_debug=0`, which are
   dropped (not required).

## What was already proven this session (don't repeat these experiments)

Done on the phone with TWRP 12.1 builds and local repacks:

| Attempt | Result | Conclusion |
|---|---|---|
| TWRP as type-2 `recovery` fragment | never loaded | this bootloader uses the `platform` fragment |
| TWRP as `platform` fragment, full ramdisk | glitch + reboot | A12 init shadowing |
| − `/init`, `/system/bin/init` | black screen | got further; stock init from `boot.img` is correct |
| − `ueventd`, `ueventd.rc` | black screen | wrong: stock vendor ramdisk is the only source of these |
| stock base + TWRP recovery binary (hybrid, 60 MB) | hang, no USB | merge correct, TWRP 12.1 userspace incompatible |
| stock ramdisk + 12 MB filler (42.5 MB) | boots | **no ramdisk size limit** |
| stock ramdisk, stock binary, our layout | boots | **repack + header geometry correct** |

Key hardware facts discovered:

- The stock `vendor_boot` has **one `platform` fragment** containing a full recovery ramdisk
  (no `/recovery` partition exists; recovery lives in `vendor_boot`).
- Stock `vendor_boot` contains **no `/init`** — init comes from `boot.img`'s ramdisk.
- `fastboot reboot recovery` does NOT work on this unit (boots normal mode, `ro.boot.mode=normal`).
  Enter recovery from the **bootloader menu**: Volume Down → "Recovery mode" → Power.
- Fastboot driver binds `USB\VID_22B8&PID_2E80`; Windows error 28 until the Motorola driver is installed.

## Verify a built image before flashing

```bash
python3 - <<'EOF'
import struct, hashlib
p = "out/target/product/vegas26/vendor_boot.img"
d = open(p, "rb").read()
hv, page = struct.unpack_from("<II", d, 8)
ka, ra, rs = struct.unpack_from("<III", d, 16)
ds = struct.unpack_from("<I", d, 8+4+4+12+2048+4+16+4)[0]
doff = (page+rs+page-1)//page*page
print("magic", d[:8], "ver", hv, "page", page)
print("kernel", hex(ka), "ramdisk", hex(ra), "size", rs)
print("dtb", ds, hashlib.sha256(d[doff:doff+ds]).hexdigest())
EOF
```

Expected: magic `VNDRBOOT`, version 4, page 4096, kernel `0x40000000`, ramdisk `0x66f00000`,
DTB size `183530` and SHA-256 `50cf268426f0c29c1081decf7e61b39c2f0be3a7d83eb39cfcb84c223934d3c8`
(the DTB must be byte-identical to stock), total ≤ 67,108,864 bytes.

If the A14 build produces a type-2 `recovery` fragment instead of a single `platform` fragment,
repack it the way that was proven to boot:

```bash
# extract the ramdisk mkbootimg packed, then repack it as the platform fragment
mkbootimg --header_version 4 --pagesize 4096 --board "" --base 0x3fff8000 \
  --kernel_offset 0x00008000 --ramdisk_offset 0x26f08000 \
  --tags_offset 0x07c88000 --dtb_offset 0x07c88000 \
  --dtb device/motorola/vegas26/prebuilt/dtb.img \
  --vendor_cmdline "bootopt=64S3,32N2,64N2" \
  --vendor_ramdisk <twrp ramdisk .lz4> --vendor_boot vendor_boot_platform.img
```

## Flash and test

```bash
adb reboot bootloader
fastboot flash vendor_boot_a vendor_boot.img     # active slot must be a
# then on the phone: Volume Down -> Recovery mode -> Power
```

Revert (always keep the stock image at hand):

```bash
fastboot flash vendor_boot_a vendor_boot_a.img
fastboot reboot
```

If it hangs: hold Power ~20 s, then Volume Down + Power to reach the bootloader.

Use platform-tools **35.0.0** or **37.0.1** — 37.0.3 stalls on `flash lk_a` (and was avoided here).

## Cautions

- Never relock the bootloader with a modified LK/init_boot.
- Never flash another device's recovery/image, including the G Play 2026 (`nevada`) ones.
- Keep `private-backups` private: `nvram`, `nvdata`, `seccomp`, `persist` contain device-unique
  calibration/security data.
- Do not accept Motorola firmware updates; the root setup depends on this exact build.
