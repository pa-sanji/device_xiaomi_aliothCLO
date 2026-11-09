#
# SPDX-FileCopyrightText: Paranoid Android
# SPDX-License-Identifier: Apache-2.0
#
# alioth ships the stock Qualcomm HIDL 2.2 perf HAL. Use it instead of the
# generic AIDL perf2 component: the stock GameOptimizationFeature (and its
# libgameoptfeature) implements the Picard 0x104A top-app hint used by the
# QTI PowerHAL, and the system perfservice/client already prefer HIDL 2.2.
#
# The blobs are the ones extracted from the alioth stock vendor image and
# live in vendor/xiaomi/alioth/proprietary. TARGET_PROVIDES_QTI_PERF_BLOBS
# (set in device.mk) keeps the generic vendor perf component from also
# installing its AIDL service and its incompatible config set.
#

PERF_STOCK := vendor/xiaomi/alioth/proprietary/vendor

# The stock perf HAL replaces the generic AIDL perf2 component, but the
# framework still expects the separate servicetracker HAL. Install only the
# servicetracker AIDL service, manifest and init script; do not inherit
# perf-vendor.mk wholesale because that also brings the incompatible generic
# perf2 service and configs.
PRODUCT_SOONG_NAMESPACES += vendor/qcom/common/vendor/perf

PRODUCT_PACKAGES += \
    vendor.qti.hardware.servicetrackeraidl-impl \
    vendor.qti.hardware.servicetrackeraidl-service \
    vendor.qti.hardware.servicetrackeraidl-service.xml

PRODUCT_COPY_FILES += \
    vendor/qcom/common/vendor/perf/proprietary/vendor/etc/init/vendor.qti.hardware.servicetrackeraidl-service.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/vendor.qti.hardware.servicetrackeraidl-service.rc

PRODUCT_COPY_FILES += \
    $(PERF_STOCK)/bin/hw/vendor.qti.hardware.perf@2.2-service:$(TARGET_COPY_OUT_VENDOR)/bin/hw/vendor.qti.hardware.perf@2.2-service \
    $(PERF_STOCK)/etc/init/vendor.qti.hardware.perf@2.2-service.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/vendor.qti.hardware.perf@2.2-service.rc \
    $(PERF_STOCK)/etc/perf/commonresourceconfigs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/perf/commonresourceconfigs.xml \
    $(PERF_STOCK)/etc/perf/commonsysnodesconfigs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/perf/commonsysnodesconfigs.xml \
    $(PERF_STOCK)/etc/perf/perfboostsconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/perf/perfboostsconfig.xml \
    $(PERF_STOCK)/etc/perf/perfconfigstore.xml:$(TARGET_COPY_OUT_VENDOR)/etc/perf/perfconfigstore.xml \
    $(PERF_STOCK)/etc/perf/targetconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/perf/targetconfig.xml \
    $(PERF_STOCK)/etc/perf/targetresourceconfigs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/perf/targetresourceconfigs.xml \
    $(PERF_STOCK)/etc/lm/AdaptLaunchFeature.xml:$(TARGET_COPY_OUT_VENDOR)/etc/lm/AdaptLaunchFeature.xml \
    $(PERF_STOCK)/etc/lm/AppClassifierFeature.xml:$(TARGET_COPY_OUT_VENDOR)/etc/lm/AppClassifierFeature.xml \
    $(PERF_STOCK)/etc/lm/GameOptimizationFeature.xml:$(TARGET_COPY_OUT_VENDOR)/etc/lm/GameOptimizationFeature.xml \
    $(PERF_STOCK)/lib64/libadaptlaunch.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libadaptlaunch.so \
    $(PERF_STOCK)/lib64/libappclassifier.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libappclassifier.so \
    $(PERF_STOCK)/lib64/libgameoptfeature.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libgameoptfeature.so \
    $(PERF_STOCK)/lib64/liblearningmodule.so:$(TARGET_COPY_OUT_VENDOR)/lib64/liblearningmodule.so \
    $(PERF_STOCK)/lib64/libmeters-ns.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libmeters-ns.so \
    $(PERF_STOCK)/lib64/libmeters.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libmeters.so \
    $(PERF_STOCK)/lib64/libperfconfig.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libperfconfig.so \
    $(PERF_STOCK)/lib64/libperfgluelayer.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libperfgluelayer.so \
    $(PERF_STOCK)/lib64/libperfioctl.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libperfioctl.so \
    $(PERF_STOCK)/lib64/libpowercallback.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libpowercallback.so \
    $(PERF_STOCK)/lib64/libpowercore.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libpowercore.so \
    $(PERF_STOCK)/lib64/libqti-perfd-client.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libqti-perfd-client.so \
    $(PERF_STOCK)/lib64/libqti-perfd.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libqti-perfd.so \
    $(PERF_STOCK)/lib64/libqti-util.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libqti-util.so \
    $(PERF_STOCK)/lib64/libqti-utils.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libqti-utils.so \
    $(PERF_STOCK)/lib64/vendor.qti.hardware.perf@2.0.so:$(TARGET_COPY_OUT_VENDOR)/lib64/vendor.qti.hardware.perf@2.0.so \
    $(PERF_STOCK)/lib64/vendor.qti.hardware.perf@2.1.so:$(TARGET_COPY_OUT_VENDOR)/lib64/vendor.qti.hardware.perf@2.1.so \
    $(PERF_STOCK)/lib64/vendor.qti.hardware.perf@2.2.so:$(TARGET_COPY_OUT_VENDOR)/lib64/vendor.qti.hardware.perf@2.2.so \
    $(PERF_STOCK)/lib64/vendor.qti.memory.pasrmanager@1.0.so:$(TARGET_COPY_OUT_VENDOR)/lib64/vendor.qti.memory.pasrmanager@1.0.so \
    $(PERF_STOCK)/lib64/vendor.qti.memory.pasrmanager@1.1.so:$(TARGET_COPY_OUT_VENDOR)/lib64/vendor.qti.memory.pasrmanager@1.1.so \
    $(PERF_STOCK)/lib/vendor.qti.hardware.perf@2.2.so:$(TARGET_COPY_OUT_VENDOR)/lib/vendor.qti.hardware.perf@2.2.so
