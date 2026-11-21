#!/system/bin/sh
# Unload the image's touch drivers, then try the stock vendor_dlkm focaltech module.
rmmod focaltech_0flash_mmi_v3 2>/dev/null
rmmod ilitek_v3_mmi 2>/dev/null
rmmod nova_0flash_mmi_v3 2>/dev/null
sleep 1
echo '--- insmod stock focaltech ---'
insmod /mnt/vdlkm/lib/modules/focaltech_0flash_mmi_v3.ko 2>&1
sleep 2
echo '--- dmesg tail ---'
dmesg | tail -40
echo '--- input devices ---'
cat /proc/bus/input/devices
echo '--- touch class ---'
ls /sys/class/touchscreen 2>/dev/null
cat /sys/class/touchscreen/primary/productinfo 2>/dev/null
echo '--- done ---'
