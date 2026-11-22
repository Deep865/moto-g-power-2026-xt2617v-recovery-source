#!/sbin/sh
# Recovery self-test. Read-only except for a temp file in /tmp and a haptic buzz.
# Output: /tmp/recovery_selftest.txt  (PASS|name|detail / FAIL|... / INFO|...)
OUT=/tmp/recovery_selftest.txt
: > "$OUT"

P() { echo "PASS|$1|$2" >> "$OUT"; }
F() { echo "FAIL|$1|$2" >> "$OUT"; }
S() { echo "SKIP|$1|$2" >> "$OUT"; }
I() { echo "INFO|$1|$2" >> "$OUT"; }

val() { getprop "$1" 2>/dev/null; }
has() { [ -n "$1" ]; }

# --- identity -------------------------------------------------------------
DEV=$(val ro.product.device)
CODE=$(val ro.build.fox_codebase)
FOX=$(val ro.orangefox.release.version)
PBRP=$(val ro.pbrp.version)
TWRP=$(val ro.twrp.version)
I identity "device=$DEV codebase=$CODE orangefox=$FOX pbrp=$PBRP twrp=$TWRP"
[ "$DEV" = "vegas26" ] && P product "vegas26" || F product "$DEV"

# --- crypto / data --------------------------------------------------------
CRYPT=$(val ro.crypto.state)
READY=$(val crypto.ready)
I crypto "ro.crypto.state=$CRYPT crypto.ready=$READY"
[ "$CRYPT" = "encrypted" ] && P crypto_state encrypted || F crypto_state "$CRYPT"
[ "$READY" = "1" ] && P crypto_ready 1 || F crypto_ready "${READY:-empty}"

if mount | grep -q ' /sdcard '; then
  P data_mount "$(mount | grep ' /sdcard ' | awk '{print $1}')"
else
  S data_mount "locked (no PIN)"
fi
if echo "selftest-ok" > /tmp/rwtest 2>/dev/null && grep -q selftest-ok /tmp/rwtest; then
  P tmp_rw ok
else
  F tmp_rw "write failed"
fi
if mount | grep -q ' /sdcard '; then
  if echo "selftest-ok" > /sdcard/_recovery_rw_test 2>/dev/null && grep -q selftest-ok /sdcard/_recovery_rw_test; then
    rm -f /sdcard/_recovery_rw_test
    P sdcard_rw ok
  else
    F sdcard_rw "not writable"
  fi
else
  S sdcard_rw "locked"
fi
DF=$(df -h /sdcard 2>/dev/null | tail -1)
I sdcard_space "$DF"

# --- TEE / gatekeeper -----------------------------------------------------
for s in keystore2 vendor.gatekeeper-1-0 vendor.keymint-trustonic mobicore; do
  st=$(val init.svc.$s)
  I "svc_$s" "${st:-unset}"
done
[ "$(readlink /vendor/lib64/hw/gatekeeper.trustonic.so 2>/dev/null)" = "libMcGatekeeper.so" ] \
  && P gatekeeper_link libMcGatekeeper.so || F gatekeeper_link "$(readlink /vendor/lib64/hw/gatekeeper.trustonic.so 2>/dev/null)"

# --- touch / panels / display --------------------------------------------
TI=$(cat /sys/class/touchscreen/primary/productinfo 2>/dev/null)
[ "$TI" = "ft8725" ] && P touch ft8725 || F touch "${TI:-missing}"
if ls /dev/input/event* >/dev/null 2>&1; then
  P input_nodes "$(ls /dev/input/event* | wc -l) events"
else
  F input_nodes none
fi
PANELS=$(ls /lib/modules 2>/dev/null | grep -c '^dsi-panel-mot')
[ "$PANELS" -ge 6 ] && P panels "$PANELS" || F panels "$PANELS"
lsmod 2>/dev/null | grep -q focaltech && P touch_module loaded || F touch_module "not loaded"
DMESG_PANEL=$(dmesg | grep -i -e 'dsi-panel' -e 'ft8725' | tail -2)
I display "$DMESG_PANEL"

# --- haptics --------------------------------------------------------------
if [ ! -e /sys/class/leds/vibrator/duration ]; then
  [ -f /lib/modules/aw862x_haptic_nv_v1.ko ] && insmod /lib/modules/aw862x_haptic_nv_v1.ko 2>/dev/null
fi
if [ -e /sys/class/leds/vibrator/duration ]; then
  P haptic_node vibrator
  echo 400 > /sys/class/leds/vibrator/duration 2>/dev/null
  echo 1 > /sys/class/leds/vibrator/activate 2>/dev/null
  sleep 1
  if dmesg | grep -q 'aw862xx_play_go'; then
    P haptic_play play_go
  else
    I haptic_play "no play_go log (may be a different driver)"
  fi
else
  F haptic_node missing
fi
lsmod 2>/dev/null | grep -q aw862x && P haptic_module loaded || F haptic_module "not loaded"

# --- storage / usb --------------------------------------------------------
for m in /vendor /vendor_dlkm /system /metadata; do
  if mount | grep -q " $m "; then P "mount$m" mounted; else I "mount$m" "not mounted"; fi
done
USB=$(val sys.usb.config); USBS=$(val sys.usb.state)
case "$USB" in *adb*) P usb_config "$USB";; *) F usb_config "${USB:-empty}";; esac
I usb_state "$USBS"
[ -d /config/usb_gadget/g1/functions ] && I usb_functions "$(ls /config/usb_gadget/g1/functions 2>/dev/null | tr '\n' ' ')"

# --- backups --------------------------------------------------------------
BK=""
for d in /sdcard/Fox/BACKUPS /sdcard/TWRP/BACKUPS /data/media/0/Fox/BACKUPS /data/media/0/TWRP/BACKUPS; do
  [ -d "$d" ] && BK="$BK $d"
done
[ -n "$BK" ] && P backup_dirs "$BK" || S backup_dirs "locked or none yet"
for d in $BK; do
  I backup_list "$d: $(ls "$d" 2>/dev/null | head -3 | tr '\n' ' ')"
done

# --- kernel / errors ------------------------------------------------------
I kernel "$(cat /proc/version 2>/dev/null)"
I slot "$(val ro.boot.slot_suffix)"
DENY=$(dmesg | grep -c 'avc: denied')
I selinux_denials "$DENY"
I recovery_log_tail "$(tail -6 /tmp/recovery.log 2>/dev/null | tr '\n' '|')"

echo "DONE" >> "$OUT"
