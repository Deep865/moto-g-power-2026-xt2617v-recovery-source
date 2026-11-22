# Recoveries

Three working `vendor_boot` images for the Moto G Power 2026 (`XT2617V`, `vegas26`).
All are 12.1-based and share the same device tree and fixes.

| Recovery | Build script | Base | Size |
|---|---|---|---|
| OrangeFox R12.0 | `scripts/91-build-ofox12-recovery.sh` | OrangeFox `fox_12.1` | ~55.1 MB |
| TWRP 3.7.1-12 | `scripts/92-build-twrp12.sh` | TWRP `twrp-12.1` | ~52.8 MB |
| PBRP 4.x | `scripts/93-build-pbrp12.sh` | PBRP `android-12.1` | ~55.1 MB |

Pick by UI: OrangeFox is the most feature-rich and MTK-friendly, TWRP is the plain
familiar UI, PBRP is TWRP-based with a different theme. All three support FT8725 touch,
FBE `/data` decryption, backups, MTP/ADB and haptics.

Full build instructions: [`BUILD-ALL.md`](../BUILD-ALL.md). Flash only to
`vendor_boot_a`, then enter recovery from the bootloader menu.

**Do not** offer 14.1/16.0 builds: both bootloop on this A16 vendor and their full
images exceed the ~55.5 MB `vendor_boot` limit.
