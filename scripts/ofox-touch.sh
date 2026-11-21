#!/system/bin/sh
mkdir -p /mnt/vdlkm
for fs in auto ext4 erofs; do
  if [ "$fs" = auto ]; then
    mount -o ro /dev/block/dm-6 /mnt/vdlkm 2>/dev/null && break
  else
    mount -t "$fs" -o ro /dev/block/dm-6 /mnt/vdlkm 2>/dev/null && break
  fi
done
echo '--- mount ---'
mount | grep -i vdlkm
echo '--- modules ---'
ls /mnt/vdlkm/lib/modules 2>/dev/null
echo '--- touch modules ---'
ls /mnt/vdlkm/lib/modules 2>/dev/null | grep -Ei 'touch|ilitek|focal|nova|goodix|synaptics|nt36|ft8|td4'
echo '--- modules.load ---'
cat /mnt/vdlkm/lib/modules/modules.load 2>/dev/null | grep -Ei 'touch|ilitek|focal|nova|goodix|synaptics|nt36|ft8|td4'
echo '--- aliases ---'
cat /mnt/vdlkm/lib/modules/modules.alias 2>/dev/null | grep -Ei 'touch|ilitek|focal|nova|goodix|synaptics|nt36|ft8|td4'
echo '--- done ---'
