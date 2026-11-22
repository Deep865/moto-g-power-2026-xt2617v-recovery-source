# Preserved upstream recovery cores

`bootable-recovery-8cd9df2b4.tar.xz` is the exact upstream **OrangeFox
`bootable/recovery`** tree at commit:

```text
8cd9df2b4cbbbf99acc3182faaa8d0f10cee9779
Fix thermal sensor reading/unsigned integer wrap for cpu temperature
```

SHA-256:

```text
e038e3f332e7f58a7cc347f9077ed753459a7349aae7f58d7d54717efdae69bf
```

Why it is here: the 12.1 core now carries the former 14.1 backports and the newer
fixes (thermal, bzip2, vibration defaults, Reboot Recovery, optional double-tap-to-
wake). Keeping the exact tree means the work cannot be lost if the upstream repo
changes or disappears. The builder still syncs a normal OrangeFox 12.1 tree and
checks out this commit; this tarball is an audit/preservation copy, not copied into
the build automatically.

Upstream: <https://gitlab.com/OrangeFox/bootable/Recovery>

Extracting:

```bash
tar -xJf bootable-recovery-8cd9df2b4.tar.xz
```

It contains the upstream licence. The device-specific changes are **not** in this
tarball; they are in this repo's `recovery/`, `prebuilt/`, `*.mk` and scripts.

## TWRP and PBRP cores

The same preservation applies to the TWRP and PBRP recovery cores used for the
tested images. Neither core was patched for this device; the device-tree changes are
in this repo. They are stored here so the exact trees survive upstream changes.

| Tarball | Commit | SHA-256 |
|---|---|---|
| `bootable-recovery-twrp-12.1-5c3d206.tar.xz` | `5c3d206a5eeb3d446bcda8248a405a4b278bab5c` | `ddffce9e3326c123846cb3eea5189908aeaeb599ee6e9ac022a65d4093de95f1` |
| `bootable-recovery-pbrp-12.1-c3ee88a.tar.xz` | `c3ee88af57d32a842b2a8ff861a72a7bf24da846` | `07b36ad3a30a7bc0d9f47e86e8b6d332604752ede66abab8f8c37286f65d7c36` |
