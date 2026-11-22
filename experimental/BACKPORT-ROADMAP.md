# Backport roadmap — newer OrangeFox features into 12.1

The 12.1 recovery is the only one that boots reliably on this `XT2617V`. We do not
ship 14.1/16.0 images. After the 2026-11-22 tests we are **not pursuing 14.1/16.0
further**; their userspace does not reach the UI on this vendor. We only backport
specific fixes that work on the 12.1 core.

## Now in the 12.1 core (`8cd9df2b4`)

| Fix | What it does |
|---|---|
| Skip data-size scan before decrypt | Avoids a hang on this encrypted `/data` |
| Alternate block-device paths | Falls back between `/dev/block/bootdevice/by-name` and `/dev/block/by-name` |
| Thermal unsigned-wrap fix | Correct CPU temperature reading |
| bzip2 | Adds `bzip2` to recovery unless `TW_EXCLUDE_BZIP2` is set |
| Vibration defaults | `OF_VIBRATION_DEFAULTS` build variable (default 40,40,160) |
| Reboot Recovery after actions | Completion pages offer Reboot Recovery |
| Double-tap-to-wake | Code present (`FOX_NO_BLANK_DT2W`), but **not enabled/tested successfully**; see note below |

The two former hand-applied patches live in `patches/historical-12.1/` for history; the
latest core already contains them. `scripts/91-build-ofox12-recovery.sh` pins the
core and does not re-apply them.

## Candidates to evaluate

These are areas where the newer branches may contain useful changes. Each one must
be reviewed against the pinned `bootable/recovery` commit (`8cd9df2b4`), not copied
blindly.

| Area | Why it might help | Risk |
|---|---|---|
| Partition/decrypt path fixes | MTK path differences cause scan/decrypt hangs | Low–medium; already two fixes here |
| Dynamic-partition / `super` handling | Backup and restore of logical partitions | Medium; must not break backups |
| Backup compression / split archives | Faster, smaller `/data` backups | Medium; old core APIs |
| USB / sideload / MTP fixes | Recovery USB reliability | Low; must pass the sideload test |
| Touch / module loading order | Avoid `ENODEV` and haptic races | Low; device tree already fixed |
| Theme/minui assets | UI polish only if it fits the size limit | Low value, high size risk |
| Updated fonts/icons | Only if the image stays under ~55.5 MB | High size risk |
| Fix dt2w for FT8725 | Upstream handler assumes a packed event; FT8725 is standard MT-B, and `TW_NO_SCREEN_BLANK` is not globally applied in the Soong GUI. Needs a proper MT tracking-id handler. | Medium |
| 14.1/16.0 UI code | Requires the newer userspace; does not fit 12.1 | **Do not attempt** |

## dt2w test (2026-11-22)

Built with `TW_NO_SCREEN_BLANK := true` + `FOX_NO_BLANK_DT2W := 1`. The screen
dimmed to 0 after the timeout, but a **single** tap woke it, not a double tap.
That is not the intended behaviour, so the flags were reverted and the tested,
published image remains the normal one. The likely causes are the upstream handler's
packed-coordinate assumption vs. the FT8725 MT-B events, and `TW_NO_SCREEN_BLANK`
not being applied to the Soong `libguitwrp`/`libminuitwrp` modules.

A follow-up MT-B/packed-event handler blocked single-tap wake, but the synthetic
double-tap test was inconclusive: each injected tap took ~238 ms, and two taps
exceeded the 450 ms window. It was not shipped. Real-finger timing may work, but
there is not enough evidence yet.

**Status:** doable in principle; needs a focused UI test pass. Not shipped.

## Rules

1. The patch must apply to `fox_12.1` at `8cd9df2b4` (or a deliberately re-pinned
   commit) and compile for `omni_vegas26-eng`.
2. The resulting image must stay under the bootloader's ~55.5 MB `vendor_boot`
   content limit. Prefer only the needed change, not newer theme/resource trees.
3. It must pass the full **17/17** recovery self-test with PIN `1234`:
   UI, touch `ft8725`, FBE decrypt, `/sdcard` read/write, gatekeeper symlink,
   haptics, MTP/ADB, six panels, `/metadata` mount and backup directories.
4. OrangeFox must still pass the ADB sideload test (`adb sideload ofox-test.zip`).
5. No regression in backup/restore or normal Android boot.
6. Record the patch, the source commit/branch, the image SHA-256 and the test
   result. Do not publish an untested image as a recovery option.

## Test loop

```bash
# build
FOX_TREE=$HOME/fox_12.1 DEVICE_TREE=$DEVICE_TREE OUT_DIR=$OUT_DIR \
  "$DEVICE_TREE/scripts/91-build-ofox12-recovery.sh"

# verify geometry
python3 "$DEVICE_TREE/scripts/extract_frags.py" "$OUT_DIR/OrangeFox-R12.0-vegas26.img" /tmp/ofox

# flash + bootloader-menu recovery, PIN 1234, then:
adb shell 'sh /tmp/recovery-selftest.sh'
adb pull /tmp/recovery_selftest.txt
```

The Windows harness used during development is `test-recovery.ps1` in the docs repo.
Keep the stock `vendor_boot_a` ready for revert.

## What not to do

- Do not replace the 12.1 platform fragment with a 14.1/16.0 one. It booted in tests
  but the recovery still did not reach a usable UI.
- Do not add the full 14.1/16.0 resource/theme tree; size and userspace are the two
  blockers.
- Do not call a newer-branch image “working” because it builds or draws a splash.
