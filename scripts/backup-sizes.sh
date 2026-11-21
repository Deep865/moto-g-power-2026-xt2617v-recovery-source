#!/system/bin/sh
echo '--- free space ---'
df -h /data
echo '--- partition sizes ---'
for p in super boot_a init_boot_a vendor_boot_a vbmeta_a vbmeta_system_a dtbo_a misc lk_a lk_b md1img_a nvram nvdata seccfg persist prodpersist proinfo protect1 protect2 frp preloader_raw_a boot_b init_boot_b vendor_boot_b; do
  sz=$(blockdev --getsize64 /dev/block/by-name/$p 2>/dev/null)
  [ -n "$sz" ] && echo "$p $sz"
done
echo '--- done ---'
