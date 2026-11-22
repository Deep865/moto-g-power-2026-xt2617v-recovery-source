# Preserved upstream recovery core

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
