# AOSP 14+ uses COMMON_LUNCH_CHOICES in AndroidProducts.mk.
# add_lunch_combo is obsolete and returns non-zero in the A16 envsetup,
# which aborts build scripts that use `set -e`.
