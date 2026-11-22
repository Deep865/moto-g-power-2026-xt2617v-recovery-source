# Recoveries

Three working `vendor_boot` images for the Moto G Power 2026 (`XT2617V`, Walmart /
Straight Talk, `vegas26`). All are 12.1-based and share the same device tree and
fixes. **Build the one you want**; you do not need all three.

| Recovery | Build sheet | Script | Base | Tested size |
|---|---|---|---|---:|
| **OrangeFox R12.0** | [orangefox/README.md](orangefox/README.md) | `scripts/91-build-ofox12-recovery.sh` | OrangeFox `fox_12.1` | 55.2 MB |
| **TWRP 3.7.1-12** | [twrp/README.md](twrp/README.md) | `scripts/92-build-twrp12.sh` | TWRP `twrp-12.1` | 52.8 MB |
| **PBRP 4.x** | [pbrp/README.md](pbrp/README.md) | `scripts/93-build-pbrp12.sh` | PBRP `android-12.1` | 54.9 MB |

Pick by UI: OrangeFox is the most feature-rich and MTK-friendly, TWRP is the plain
familiar UI, PBRP is TWRP-based with a different theme. All three support FT8725
touch, FBE `/data` decryption, backup/restore, MTP/ADB, haptics and six 1080×2388
panel modules.

## Flash

```powershell
fastboot flash vendor_boot_a <recovery>.img
```

Then enter recovery from the **bootloader menu**: **Volume Down → Recovery mode →
Power**. `fastboot reboot recovery` boots normal Android on this unit. Keep the stock
`vendor_boot_a` for revert.

## Tested binaries

<https://github.com/Deep865/moto-g-power-2026-xt2617v-walmart-unlock-degoogle-guide/releases/tag/2026-11-22>

| Image | SHA-256 |
|---|---|
| OrangeFox | `9cd709698b444658d5db5bbbe047429bebfc2ce4209e1b08c377d591ff1a24a0` |
| TWRP | `0a241558f40d4cd18b0b2299d0018ac0154362045691b329c8bfb4a6d562c5d7` |
| PBRP | `c899f61ee38ad14ecccd352fa06fcf9e61737698487eb83001ec4a3d95d977cb` |

## Not offered

**OrangeFox 14.1 / 16.0** do not reach a usable UI on this A16 vendor, and their full
images can exceed the ~55.5 MB `vendor_boot` limit. Do not flash them expecting a
recovery. We track useful fixes to backport into 12.1 in
[`../experimental/BACKPORT-ROADMAP.md`](../experimental/BACKPORT-ROADMAP.md).

Full build guide: [`../BUILD-ALL.md`](../BUILD-ALL.md).
