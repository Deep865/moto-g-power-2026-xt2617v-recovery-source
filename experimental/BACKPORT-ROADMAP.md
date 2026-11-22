# Backport roadmap — newer OrangeFox features into 12.1

The 12.1 recovery is the only one that boots reliably on this `XT2617V`. We do not
ship 14.1/16.0 images. Instead, we backport specific fixes from the newer branches
when they are useful, small and testable on the 12.1 core.

## Already backported (in `patches/12.1/`)

| Patch | What it does | Origin |
|---|---|---|
| `0001-partition-skip-data-size.patch` | Skip the data-size scan before decryption, avoiding a hang on this encrypted `/data` | OrangeFox 14.1 |
| `0002-alt-block-device-paths.patch` | Fall back between `/dev/block/bootdevice/by-name` and `/dev/block/by-name` | OrangeFox 14.1 |

Both are applied by `scripts/91-build-ofox12-recovery.sh` and were part of the
17/17-tested OrangeFox image.

## Candidates to evaluate

These are areas where the newer branches may contain useful changes. Each one must
be reviewed against the pinned `bootable/recovery` commit (`3fc9e73f`), not copied
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
| 14.1/16.0 UI code | Requires the newer userspace; does not fit 12.1 | **Do not attempt** |

## Rules

1. The patch must apply to `fox_12.1` at `3fc9e73f` (or a deliberately re-pinned
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
