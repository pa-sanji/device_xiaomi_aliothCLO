# SPDX-License-Identifier: Apache-2.0
#
# Stage 1 of the Tsaritsa-Prjkt/android_hardware_dolby switch:
# audio/Dolby only. The Dolby Vision / C2 / DVS parts of hardware/dolby
# are intentionally left out until the audio stack has been validated.

DOLBY_PATH := hardware/dolby

PRODUCT_SOONG_NAMESPACES += \
    $(DOLBY_PATH)

# The software DAP effect is the one exposed by audio_effects.xml.
AUDIO_FEATURE_ENABLED_DS2_DOLBY_DAP := true

# DMS 2.0 VINTF manifest
PRODUCT_PACKAGES += \
    vendor.dolby.hardware.dms@2.0-service.xml

# Init
PRODUCT_PACKAGES += \
    init.dolby.rc

# Framework resource overlay
PRODUCT_PACKAGES += \
    DolbyFrameworksResCommon

# Dolby configuration
PRODUCT_COPY_FILES += \
    $(DOLBY_PATH)/proprietary/vendor/etc/init/vendor.dolby.hardware.dms@2.0-service.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/vendor.dolby.hardware.dms@2.0-service.rc \
    $(DOLBY_PATH)/proprietary/vendor/etc/media_codecs_dolby_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_dolby_audio.xml

PRODUCT_COPY_FILES += \
    $(DOLBY_PATH)/proprietary/vendor/etc/dolby/dax-default-spatializer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/dolby/dax-default-spatializer.xml \
    $(DOLBY_PATH)/proprietary/vendor/etc/dolby/dax-default.xml:$(TARGET_COPY_OUT_VENDOR)/etc/dolby/dax-default.xml \
    $(DOLBY_PATH)/proprietary/vendor/etc/dolby/dax-moto_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/dolby/dax-moto_1.xml \
    $(DOLBY_PATH)/proprietary/vendor/etc/dolby/dax-moto_2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/dolby/dax-moto_2.xml \
    $(DOLBY_PATH)/proprietary/vendor/etc/dolby/dax-moto_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/dolby/dax-moto_3.xml

# Remove the stock effects apps that LunarisDolby replaces.
PRODUCT_PACKAGES += \
    RemovePackagesDolby

# Dolby apps
PRODUCT_PACKAGES += \
    DSPVolumeSynchronizer \
    LunarisDolby

# Dolby DMS HAL and the effect-side libraries.
PRODUCT_PACKAGES += \
    libdapparamstorage \
    libdapparamstorage-dolby \
    libdapparamstorage-spatial \
    libspatializerparamstorage \
    libdlbdsservice \
    libdlbpreg \
    libdlbvol \
    liboem_specific \
    libswdap \
    libswgamedap \
    libswvqe \
    libswspatializer \
    libstagefright_foundation-v33.vendor \
    libstagefright_foundation-dolby \
    libstagefright_foundation-atmos \
    libstagefright_foundation-spatial \
    vendor.dolby.hardware.dms@2.0-atmos.so \
    vendor.dolby.hardware.dms@2.0-dolby \
    vendor.dolby.hardware.dms@2.0-impl \
    vendor.dolby.hardware.dms@2.0-service \
    vendor.dolby.hardware.dms@2.0-spatial \
    vendor.dolby.hardware.dms@2.0

# Dolby spatial audio
PRODUCT_SYSTEM_EXT_PROPERTIES += \
    ro.audio.spatializer_enabled=true \
    ro.audio.spatializer_transaural_enabled_default=false \
    ro.audio.stereo_spatialization_enabled=true \
    persist.vendor.audio.spatializer.speaker_enabled=false

# Dolby properties. DAX 3.7 matches the Tsaritsa stack.
PRODUCT_VENDOR_PROPERTIES += \
    ro.vendor.dolby.dax.version=DAX3_3.7.0.8_r1 \
    vendor.audio.dolby.ds2.hardbypass=false \
    vendor.audio.dolby.ds2.enabled=false
