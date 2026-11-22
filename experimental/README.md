# Experimental notes — 14.1 and 16.0

> **Not supported, not published, do not flash expecting a recovery.**

Both OrangeFox 14.1 and 16.0 build and pass header/DTB/fragment checks, but they
do **not** reach a usable recovery UI on this phone's Android 16 vendor. Their full
images can also exceed the bootloader's ~55.5 MB `vendor_boot` content limit. TWRP
14.1 has the same userspace blocker.

Supported builds are only the three 12.1 recoveries in [`../recoveries/`](../recoveries/).

## Files here

| File | Contents |
|---|---|
| `BUILD-14.1-16.0.md` | Historical build notes for TWRP 14.1, OrangeFox 14.1/16.0, the A14 fixes, repacks and failure modes |
| `BACKPORT-ROADMAP.md` | What we want to bring from the newer branches into 12.1, and how it is tested |

## Scripts

`../scripts/experimental/` has the old build/repack scripts. They are kept for
reference only; paths and assumptions differ from the supported builders.

## Why keep the history

The experiments established:

- the exact `vendor_boot` header/DTB/fragment layout and the ~55.5 MB content limit;
- that the 14.1/16.0 recovery **userspace** fails before USB/display takeover, not the
  image format;
- that a newer platform fragment with an older recovery can load, but the newer
  recovery still only draws the splash;
- the 14.1 fixes that were useful enough to backport to 12.1; the latest
  `fox_12.1` core now carries them upstream.

Full on-device notes and failure hashes are in the docs repo `docs/05-ofox16.md` and
`docs/11-recovery-test-results.md`.

## Rule for adding anything here to a release

A newer-branch feature is only supported after it is backported into the 12.1 tree,
the image stays under the size limit, and it passes the full 17/17 recovery
self-test plus sideload. Do not publish a 14.1/16.0 image as a recovery option.
