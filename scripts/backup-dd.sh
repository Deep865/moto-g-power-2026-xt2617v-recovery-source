#!/system/bin/sh
D=/data/local/tmp/backup-20261121
mkdir -p "$D"
: > "$D/SHA256SUMS.txt"
for p in super boot_a init_boot_a vendor_boot_a vbmeta_a vbmeta_system_a dtbo_a misc lk_a lk_b md1img_a nvram nvdata seccfg persist prodpersist proinfo protect1 protect2 frp preloader_raw_a boot_b init_boot_b vendor_boot_b; do
  echo "=== $p ==="
  if dd if=/dev/block/by-name/$p of="$D/$p.img" bs=4M 2>/dev/null; then
    sha256sum "$D/$p.img" >> "$D/SHA256SUMS.txt"
  else
    echo "FAILED $p"
  fi
done
sync
echo '=== result ==='
ls -lh "$D"
