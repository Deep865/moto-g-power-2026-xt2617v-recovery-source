# Historical OrangeFox 14.1 backports

`0001-partition-skip-data-size.patch` and `0002-alt-block-device-paths.patch` were
used while this tree was pinned to `bootable/recovery` `3fc9e73f`.

They are **already in the latest `fox_12.1` core (`8cd9df2b4`)** and
`scripts/91-build-ofox12-recovery.sh` no longer applies them. They are kept for
history/review; do not apply them on top of `8cd9df2b4`.

The newer core also adds the thermal-sensor fix, bzip2, configurable vibration
defaults, Reboot Recovery after actions and optional double-tap-to-wake.
