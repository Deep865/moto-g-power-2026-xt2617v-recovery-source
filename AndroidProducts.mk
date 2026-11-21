#OrangeFox/TWRP Config
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_vegas26.mk \
    $(LOCAL_DIR)/omni_vegas26.mk

COMMON_LUNCH_CHOICES := \
    twrp_vegas26-user \
    twrp_vegas26-userdebug \
    twrp_vegas26-eng \
    omni_vegas26-user \
    omni_vegas26-userdebug \
    omni_vegas26-eng
