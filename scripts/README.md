# Scripts

The supported build path is three scripts, one per working recovery:

| Script | Recovery | Output |
|---|---|---|
| `91-build-ofox12-recovery.sh` | OrangeFox R12.0 | `OrangeFox-R12.0-vegas26.img` |
| `92-build-twrp12.sh` | TWRP 3.7.1-12 | `TWRP-3.7.1-12-vegas26.img` |
| `93-build-pbrp12.sh` | PBRP 4.x | `PBRP-4.x-vegas26.img` |
| `build-all-three.sh` | all / subset | all three |

Each builder copies the tree to `device/motorola/vegas26` in the recovery checkout,
applies the fixes, runs `lunch` + `mka vendorbootimage`, and copies the padded image
to `$OUT_DIR`.

## Required environment

```bash
DEVICE_TREE=/path/to/moto-g-power-2026-xt2617v-walmart-recovery-source
OUT_DIR=$HOME/recovery-images
```

Then set one of `FOX_TREE`, `TWRP_TREE`, `PBRP_TREE` for the script you run. See
[`../recoveries/`](../recoveries/) and [`../BUILD-ALL.md`](../BUILD-ALL.md).

## Test / inspect

| Script | Purpose |
|---|---|
| `recovery-selftest.sh` | push to `/tmp` in recovery; writes `/tmp/recovery_selftest.txt` (PASS/FAIL/INFO) |
| `extract_frags.py` | dump vendor_boot header, DTB and fragments |
| `verify_built.py` | compare header, DTB, addresses, size and fragments against a reference |
| `backup-dd.sh` | `dd` the key partitions from root Android (keep the output private) |
| `backup-sizes.sh` | list partition sizes and free space |
| `start-ofox12.sh` | convenience launcher for an existing OrangeFox 12.1 tree |

Run shell scripts with `bash`, not `sh`.

## Experimental / legacy

`scripts/experimental/` contains the 14.1/16.0 experiments, the older XDA-prebuilt
repack, and the first 12.1 source build that `91` supersedes. They are kept for
history and are **not turnkey**: paths and assumptions differ. See
[`experimental/README.md`](experimental/README.md).

## Cautions

- `backup-dd.sh` includes `nvram`, `nvdata`, `seccfg`, `persist`, `frp`, `protect*`
  and `md1img`. Keep those private.
- Do not flash without verifying the image and keeping a stock `vendor_boot_a`.
- The CRLF/symlink traps are why the builders fix the tree after copying it.
