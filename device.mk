# Copyright (C) 2021 Paranoid Android
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

# Debug tools (boot logger, dlopener, strace)
$(call inherit-product, hardware/samsung-ext/interfaces/debug-tools/debug.mk)

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=ext4 \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# AAPT
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi

# BPF
# The 4.19 MagicTime kernel carries the 5.10 BPF backports. Report the
# backported version so netd/bpfloader can use the newer programs.
PRODUCT_PRODUCT_PROPERTIES += \
    ro.bpf.kver_override=5.10.239

# Adaptive Suspend
PRODUCT_PROPERTY_OVERRIDES += \
    suspend.short_suspend_threshold_millis=5000

# ANT+
PRODUCT_PACKAGES += \
    com.dsi.ant@1.0.vendor

# ART
PRODUCT_ENABLE_UFFD_GC := true

# Attestation
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.device_id_attestation.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_id_attestation.xml

# Audio
# Matches the AOSPA kona alioth recipe (aospa-kona/android_device_xiaomi_alioth
# vauxite): the MIUI prebuilt primary HAL from proprietary_vendor_xiaomi plus
# the qti kona audio configuration, with the platform audio component (qti
# audio) providing the HIDL service, effect modules and policy copies.
PRODUCT_PACKAGES += \
    libqcompostprocbundle \
    libqcomvisualizer \
    libqcomvoiceprocessing

# HIDL service + impls, kept explicit so the 32-bit legacy HAL wrapper is
# always packaged at the path init expects (audio.primary.kona itself comes
# from qti-audio.mk -> configs/kona/kona.mk).
PRODUCT_PACKAGES += \
    android.hardware.audio@6.0-impl \
    android.hardware.audio.effect@6.0-impl \
    android.hardware.audio.service \
    audio.primary.kona

# The prebuilt primary HAL (vendor/lib/hw/audio.primary.alioth.so) has a hard
# DT_NEEDED on libaudioroute-v34.so, the VNDK-34 flavoured audioroute:
#
#   readelf -d .../audio.primary.alioth.so | grep audioroute
#       [NEEDED] libaudioroute-v34.so
#       [NEEDED] libaudioroute_ext.so
#
# hardware/lineage/compat provides that module (prebuilt vndk/v34). Without it
# the linker cannot load the blob; nothing else pulls it in automatically.
PRODUCT_PACKAGES += \
    libaudioroute-v34

PRODUCT_VENDOR_PROPERTIES += \
    persist.vendor.audio.delta.refresh=true \
    persist.vendor.audio.misound.disable=true \
    persist.vendor.audio.ring.filter.mask=0 \
    ro.audio.monitorRotation=true \
    ro.config.vc_call_vol_steps=11 \
    ro.hardware.audio.primary=alioth \
    ro.vendor.audio.enhance.support=false \
    ro.vendor.audio.gain.support=true \
    ro.vendor.audio.karaok.support=true \
    ro.vendor.audio.ns.support=false \
    ro.vendor.audio.scenario.support=true \
    ro.vendor.audio.soundfx.type=mi \
    ro.vendor.audio.soundfx.usb=true \
    ro.vendor.audio.support.sound.id=true \
    ro.vendor.audio.us.proximity=true \
    ro.vendor.audio.us.type=mius \
    ro.vendor.audio.zoom.support=true \
    ro.vendor.audio.zoom.type=1 \
    vendor.audio.spkcal.copy.inhal=true \
    vendor.audio.usb.disable.sidetone=true

# The MIUI primary HAL blocks inside adev_open_input_stream() for the first
# boot-time input probe on this kernel (builds #43-#46: io_handle 14 never
# returned and the system server watchdog-looped at StartAudioService). A17's
# AudioPolicyManager probes every input profile at boot; the aospa-kona
# reference is an Android 14 tree whose ROM does not hit this. Skip the input
# probing (frameworks/av patch, default true) so the blob can boot; input
# devices are validated on first use instead.
PRODUCT_SYSTEM_PROPERTIES += \
    ro.audio.probe_input_profiles=false \
    ro.audio.usb.period_us=20375 \
    af.resampler.quality=7 \
    ro.audio.resampler.psd.stopband=132 \
    ro.audio.resampler.psd.halflength=960 \
    ro.audio.resampler.psd.cutoff_percent=98 \
    ro.audio.resampler.psd.tbwcheat=0 \
    persist.bluetooth.sbc_hd_higher_bitrate=1 \
    persist.vendor.audio_hal.dsp_bit_width_enforce_mode=24

# SSREC is reported unsupported on alioth ("surround sound recording is not
# supported"), and the source-built libssrec.so disagrees with the MIUI HAL
# blob on struct stream_in layout:
#   stock MIUI lib: channel_mask@0xb0, device_list@0xa8
#   our CAF lib:    channel_mask@0xb4, device_list@0xac
# The blob passes &in->device_list at 0xa8, so the lib walks a garbage,
# self-linked pointer and adev_open_input_stream never returns. That blocks
# the HAL, and the AudioFlinger timecheck aborts audioserver on camera
# recording (CAMCORDER / BACK_MIC). Disable the feature so the blob never
# loads the mismatched library.
PRODUCT_ODM_PROPERTIES += \
    aaudio.mmap_policy=1 \
    ro.vendor.audio.sdk.fluencetype=fluence \
    vendor.audio.adm.buffering.ms=6 \
    vendor.audio.feature.dynamic_ecns.enable=false \
    vendor.audio.feature.spkr_prot.enable=false \
    vendor.audio.feature.ssrec.enable=false \
    vendor.audio.hal.output.suspend.supported=false \
    vendor.audio.offload.multiple.enabled=true \
    vendor.audio.offload.track.enable=false \
    vendor.audio.offload.buffer.size.kb=256

# Audio input-hang diagnostics (temporary bring-up build).
# The MIUI HAL hangs in adev_open_input_stream() for CAMCORDER/BACK_MIC; enable
# verbose logging for every HAL/AudioFlinger tag involved so the last executed
# step is visible in logcat. The 60 s timecheck keeps audioserver alive long
# enough to dump the audio HAL stack before the watchdog aborts it.
PRODUCT_VENDOR_PROPERTIES += \
    log.tag.audio_hw_primary=V \
    log.tag.audio_hw_extn=V \
    log.tag.audio_hw_utils=V \
    log.tag.audio_hw_acdb=V \
    log.tag.audio_hw_cin=V \
    log.tag.audio_hw_compress=V \
    log.tag.audio_hw_ssr=V \
    log.tag.audio_hw_sndmonitor=V \
    log.tag.audio_hw_hfp=V \
    log.tag.audio_hw_cspl_cal=V \
    log.tag.audio_hw_hidl=V \
    log.tag.audio_hw_usb=V \
    log.tag.audio_hw_call_back=V \
    log.tag.audio_hw_dev_arbi=V \
    log.tag.audio_hw_dolby=V \
    log.tag.platform_info=V \
    log.tag.msm8974_platform=V \
    log.tag.soundtrigger=V \
    log.tag.sound_trigger_hw=V \
    log.tag.sound_trigger_platform=V \
    log.tag.voice=V \
    log.tag.voice_extn=V

PRODUCT_SYSTEM_PROPERTIES += \
    log.tag.AudioFlinger=V \
    log.tag.AudioPolicyManager=V \
    log.tag.AudioPolicyService=V \
    log.tag.AudioRecord=V \
    log.tag.AudioSystem=V \
    log.tag.AudioTrack=V \
    log.tag.MediaRecorder=V \
    ro.logd.size=16M \
    ro.logd.size.main=16M \
    ro.logd.size.system=16M \
    ro.logd.size.crash=16M

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/mixer_paths_overlay_static.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths_overlay_static.xml \
    $(LOCAL_PATH)/configs/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/audio_policy_configuration.xml \
    $(LOCAL_PATH)/configs/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    $(LOCAL_PATH)/configs/audio/audio_io_policy.conf:$(TARGET_COPY_OUT_VENDOR)/etc/audio_io_policy.conf

# Dolby
# Xiaomi QDSP DAP integration, ported from PocoF3Releases (device_xiaomi_sm8250-common
# aosp-17 and hardware_xiaomi cnb). The MIUI primary HAL drives the ADSP DAP module
# already present in the vendor tree (vendor/lib/rfsa/adsp/capi_v2_dap_cpdp.so); the
# DMS HAL exposes the QDSP effect parameters to AudioFlinger through the "dap" effect,
# and XiaomiDolby is the system app that controls it.
include hardware/xiaomi/dolby/dolby.mk

PRODUCT_PACKAGES += \
    DSPVolumeSynchronizer \
    XiaomiDolby \
    libstagefright_foundation-v33.vendor

PRODUCT_VENDOR_PROPERTIES += \
    ro.vendor.audio.dolby.dap.control=qdsp \
    ro.vendor.audio.dolby.dax.support=true \
    ro.vendor.audio.dolby.dax.version=DAX3_3.6 \
    ro.vendor.audio.dolby.spatializer.support?=false \
    ro.vendor.audio.dolby.speaker_tuning.support?=false \
    ro.vendor.audio.dolby.surround.enable=true \
    ro.vendor.dolby.dax.version=DAX3_3.6.1.6_r1 \
    vendor.audio.dolby.control.tunning.by.volume.support?=false

# Battery
PRODUCT_SYSTEM_PROPERTIES += \
    ro.config.small_battery=true

# Bluetooth
PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.1.vendor \
    audio.bluetooth.default \
    com.qualcomm.qti.bluetooth_audio@1.0.vendor \
    libldacBT_enc \
    libldacBT_abr \
    vendor.qti.hardware.bluetooth_audio@2.1.vendor \
    vendor.qti.hardware.btconfigstore@1.0.vendor \
    vendor.qti.hardware.btconfigstore@2.0.vendor

PRODUCT_VENDOR_PROPERTIES += \
    persist.sys.fflag.override.settings_bluetooth_hearing_aid=true \
    persist.vendor.qcom.bluetooth.a2dp_mcast_test.enabled=false \
    persist.vendor.qcom.bluetooth.a2dp_offload_cap=sbc-aptx-aptxtws-aptxhd-aac-ldac-aptxadaptiver2 \
    persist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true \
    persist.vendor.qcom.bluetooth.aac_vbr_ctl.enabled=true \
    persist.vendor.qcom.bluetooth.aptxadaptiver2_1_support=true \
    persist.vendor.qcom.bluetooth.enable.splita2dp=true \
    persist.vendor.qcom.bluetooth.enable.swb=false \
    persist.vendor.qcom.bluetooth.enable.swbpm=false \
    persist.vendor.qcom.bluetooth.scram.enabled=false \
    persist.vendor.qcom.bluetooth.soc=hastings \
    persist.vendor.qcom.bluetooth.twsp_state.enabled=false \
    ro.vendor.bluetooth.wipower=false \
    vendor.hw.fm.init=0 \
    vendor.qcom.bluetooth.soc=hastings

PRODUCT_SYSTEM_PROPERTIES += \
    vendor.bluetooth.soc=hastings

PRODUCT_SYSTEM_EXT_PROPERTIES += \
    persist.vendor.btstack.a2dp_offload_cap=sbc-aptx-aptxtws-aptxhd-aptxadaptiver2-aac-ldac \
    persist.vendor.btstack.connect.peer_earbud=true \
    persist.vendor.btstack.enable.lpa=true \
    persist.vendor.btstack.enable.splita2dp=true \
    persist.vendor.btstack.enable.swb=false \
    persist.vendor.btstack.enable.swbpm=false \
    persist.vendor.btstack.enable.twsplus=true \
    persist.vendor.btstack.enable.twsplussho=true

# Boot
PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery

$(call soong_config_set,QTI_GPT_UTILS,USE_BSG_FRAMEWORK,false)

# Camera
PRODUCT_VENDOR_PROPERTIES += \
    camera.disable_zsl_mode=true

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/camera/st_license.lic:$(TARGET_COPY_OUT_VENDOR)/etc/camera/st_license.lic

PRODUCT_PACKAGES += \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service_64 \
    libcamera2ndk_vendor \
    libpng.vendor \
    libstdc++.vendor \
    vendor.qti.hardware.camera.device@1.0.vendor \
    vendor.qti.hardware.camera.postproc@1.0.vendor

PRODUCT_PACKAGES += \
    libpiex_shim \
    libutilscallstack.vendor

# Xiaomi Camera (MiuiCamera)
# Device-side integration from PocoF3Releases device_xiaomi_camera (aosp-17):
# permissions, device features, CamX overrides, SELinux policy, JNI shims and
# the MiuiCameraOverlay RRO, plus the proprietary APK/libs from
# pa-sanji/vendor_xiaomi_camera (aosp-17, mirror of the upstream
# johnmart19/vendor_xiaomi_camera repository). The camxoverridesettings.txt it
# installs is byte-identical to the copy previously made from configs/camera,
# which is why that duplicate copy rule is removed above.
-include device/xiaomi/camera/miuicamera.mk

# Cgroup and task_profiles
PRODUCT_COPY_FILES += \
    system/core/libprocessgroup/profiles/cgroups.json:$(TARGET_COPY_OUT_VENDOR)/etc/cgroups.json \
    system/core/libprocessgroup/profiles/task_profiles.json:$(TARGET_COPY_OUT_VENDOR)/etc/task_profiles.json

# Charging
PRODUCT_VENDOR_PROPERTIES += \
    persist.vendor.cp.fcc_main_ua=400000 \
    persist.vendor.cp.taper_term_mv=7000 \
    persist.vendor.cp.qc3p5_vfloat_offset_uv=110000 \
    persist.vendor.pps.disallowed=1 \
    persist.vendor.hvdcp_opti.disallowed=1

# Consumer IR
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.consumerir.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.consumerir.xml

PRODUCT_PACKAGES += \
    android.hardware.ir-service.xiaomi

# Dalvik
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

# Device Settings
PRODUCT_PACKAGES += \
    XiaomiParts

# Display
PRODUCT_VENDOR_PROPERTIES += \
    persist.sys.sf.native_mode=269 \
    ro.surface_flinger.supports_background_blur=1 \
    ro.vendor.display.paneltype=2 \
    ro.vendor.display.sensortype=2 \
    vendor.display.qdcm.mode_combine=1 \
    vendor.display.defer_fps_frame_count=2 \
    vendor.display.vds_allow_hwc=1 \
    debug.sf.disable_client_composition_cache=0 \
    debug.sf.defer_refresh_rate_when_off=1

PRODUCT_ODM_PROPERTIES += \
    vendor.display.use_smooth_motion=0

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.surface_flinger.set_idle_timer_ms=4000 \
    ro.surface_flinger.set_touch_timer_ms=4000 \
    ro.surface_flinger.set_display_power_timer_ms=1000 \
    ro.surface_flinger.use_content_detection_for_refresh_rate=true \
    debug.hwui.skia_tracing_enabled=false \
    debug.hwui.skia_use_perfetto_track_events=false \
    debug.sf.treat_170m_as_sRGB=1 \
    debug.sf.hwc_hotplug_error_via_neg_vsync=1 \
    debug.sf.hwc_hdcp_via_neg_vsync=1 \
    ro.surface_flinger.enable_layer_caching=false

# NOTE: do not set ro.config.avoid_gfx_accel=true here. ActivityManager
# .isHighEndGfx() returns false when it is set, which makes SystemUI's
# BlurUtils.supportsBlursOnWindows() return false and disables window blur
# unconditionally (even though WindowManager reports mBlurEnabled=true).
# It was inherited from the pipa-port tree and is not set by the reference.

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    debug.sf.enable_transaction_tracing=false

PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/configs/display/,$(TARGET_COPY_OUT_VENDOR)/etc)

TARGET_USE_AIDL_QTI_MEMTRACK := true

# DPM
PRODUCT_VENDOR_PROPERTIES += \
    persist.vendor.dpmhalservice.enable=1

# DRM
PRODUCT_VENDOR_PROPERTIES += \
    drm.service.enabled=true

PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey \
    libcrypto_shim.vendor

# Fastboot
PRODUCT_PACKAGES += \
    fastbootd

# Fingerprint
# AOSPA alioth ships the prebuilt MIUI HIDL @2.1 service
# (vendor/bin/hw/android.hardware.biometrics.fingerprint@2.1-service, its rc
# and VINTF fragments) with the FPC blob, installed from the vendor tree by
# alioth-vendor.mk. The framework uses the HIDL path, selected by the non-empty
# config_biometric_sensors in the AliothFrameworks overlay.


PRODUCT_VENDOR_PROPERTIES += \
    persist.vendor.fingerprint.sensor_location=1080|965|115|local:4630946736638489729 \
    persist.vendor.fingerprint.type=side

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/fingerprint/uinput-fpc.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/uinput-fpc.kl \
    $(LOCAL_PATH)/configs/fingerprint/uinput-fpc.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/uinput-fpc.idc \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml

# Gatekeeper
PRODUCT_VENDOR_PROPERTIES += \
    vendor.gatekeeper.disable_spu=true

# Gboard paddings
# Keyboard height ratio and bottom padding in dp for portrait mode
PRODUCT_PRODUCT_PROPERTIES += \
    ro.com.google.ime.height_ratio=1.075 \
    ro.com.google.ime.kb_pad_port_b=8

# GPS
PRODUCT_PACKAGES += \
    libcurl.vendor

# Init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/fstab.qcom:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.qcom

PRODUCT_PACKAGES += \
    fstab.qcom \
    init.alioth.rc \
    init.mi.btmac.sh \
    init.qti.dcvs.sh \
    init.target.rc \
    ueventd.alioth.rc

# Keymaster
PRODUCT_VENDOR_PROPERTIES += \
    ro.crypto.allow_encrypt_override=true \
    ro.crypto.volume.filenames_mode="aes-256-cts" \
    ro.hardware.keystore_desede=true

# limit DPP downscale ratio
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    vendor.hwc.dpp.downscale=4

# Lineage Health
PRODUCT_PACKAGES += \
    vendor.lineage.health-service.default

TARGET_HEALTH_CHARGING_CONTROL_SUPPORTS_BYPASS := false

# Logging
SPAMMY_LOG_TAGS := \
    AiAiEcho \
    AiAiTextClassifier \
    BaseDepthController \
    GraphicsEnvironment \
    Diag_Lib \
    CCodec \
    CCodecBuffers \
    CCodecConfig \
    Codec2Client \
    MiStcImpl \
    SDM \
    SRE \
    WifiHAL \
    WifiService \
    cnss-daemon \
    CameraService \
    ForegroundUtils \
    sensors \
    sensors-hal \
    a2dp_offload \
    bluetooth-a2dp \
    BluetoothMetrics \
    vendor.qti.bluetooth@1.0-ibs_handler \
    vendor.qti.bluetooth@1.0-patch_dl_manager \
    vendor.qti.bluetooth@1.0-wake_lock \
    DisplayManagerService \
    DisplayModeController \
    FrameTracker \
    QC2GrallocBuffer \
    tftp_server \
    LOWI-9.0.1.89.z \
    wpa_supplicant \
    InetDiagMessage \
    QtiCarrierConfigHelper \
    DeviceStatisticsService \
    DeviceInfoHidlClient \
    NearbyDiscovery \
    NearbyPresence \
    NearbySharing \
    GmsClient

ifneq ($(TARGET_BUILD_VARIANT),eng)
PRODUCT_VENDOR_PROPERTIES += \
    $(foreach tag,$(SPAMMY_LOG_TAGS),log.tag.$(tag)=E)
endif

# Media
# OMX stays enabled: the camera MediaRecorder resolves its AAC encoder through
# the OMX store (OMX.qcom.audio.encoder.aac from libOmxAacEnc), and the Dolby
# AC-4/E-AC-3/DD+ decoders are OMX components as well. The reference build also
# keeps OMX enabled.
TARGET_SUPPORTS_OMX_SERVICE := false

PRODUCT_VENDOR_PROPERTIES += \
    debug.stagefright.c2inputsurface=-1 \
    ro.odm.build.media_performance_class=30

# AOSP software codec lists referenced by media_codecs.xml (audio/AAC,
# telephony and software video fallbacks).
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_telephony.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_video.xml

# OMX plumbing used by the vendor OMX service for the software/vendor codecs.
PRODUCT_PACKAGES += \
    libcodec2_hidl@1.0.vendor \
    libcodec2_soft_common.vendor \
    libstagefright_omx.vendor \
    libstagefright_softomx.vendor \
    libstagefright_softomx_plugin.vendor

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/media/media_codecs_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_c2.xml \
    $(LOCAL_PATH)/configs/media/media_codecs_performance_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_performance_c2.xml \
    $(LOCAL_PATH)/configs/media/video_system_specs.json:$(TARGET_COPY_OUT_VENDOR)/etc/video_system_specs.json

# Namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/xiaomi

# Net
PRODUCT_PACKAGES += \
    android.system.net.netd@1.1.vendor

# NFC
PRODUCT_PACKAGES += \
    android.hardware.nfc-service.nxp \
    com.android.nfc_extras \
    libchrome.vendor \
    NfcNci \
    Tag \
    se_nq_extn_client \
    ls_nq_client \
    jcos_nq_client

PRODUCT_SYSTEM_PROPERTIES += \
    ro.nfc.port=I2C

ifneq ($(TARGET_NFC_SKU),)
NFC_PERMISSIONS_DIR := $(TARGET_COPY_OUT_ODM)/etc/permissions/sku_$(TARGET_NFC_SKU)
else
NFC_PERMISSIONS_DIR := $(TARGET_COPY_OUT_VENDOR)/etc/permissions
endif

PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/configs/nfc/,$(TARGET_COPY_OUT_VENDOR)/etc) \
    frameworks/native/data/etc/android.hardware.nfc.ese.xml:$(NFC_PERMISSIONS_DIR)/android.hardware.nfc.ese.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(NFC_PERMISSIONS_DIR)/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.hcef.xml:$(NFC_PERMISSIONS_DIR)/android.hardware.nfc.hcef.xml \
    frameworks/native/data/etc/android.hardware.nfc.uicc.xml:$(NFC_PERMISSIONS_DIR)/android.hardware.nfc.uicc.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(NFC_PERMISSIONS_DIR)/android.hardware.nfc.xml \
    frameworks/native/data/etc/android.hardware.se.omapi.ese.xml:$(NFC_PERMISSIONS_DIR)/android.hardware.se.omapi.ese.xml \
    frameworks/native/data/etc/android.hardware.se.omapi.uicc.xml:$(NFC_PERMISSIONS_DIR)/android.hardware.se.omapi.uicc.xml \
    frameworks/native/data/etc/com.android.nfc_extras.xml:$(NFC_PERMISSIONS_DIR)/com.android.nfc_extras.xml \
    frameworks/native/data/etc/com.nxp.mifare.xml:$(TARGET_COPY_OUT_ODM)/etc/permissions/com.nxp.mifare.xml

# Overlays
PRODUCT_PACKAGES += \
    aptxalsOverlay \
    AliothCarrierConfig \
    AliothFrameworks \
    AliothNfc \
    AliothSettings \
    AliothSystemUI \
    AOSPAAliothFrameworks \
    AOSPAAliothSystemUI \
    SettingsOverlayM2012K11AG \
    SettingsOverlayM2012K11AI \
    SettingsProviderM2012K11AC \
    SettingsProviderM2012K11AG \
    SettingsProviderM2012K11AI \
    WifiMainline \
    WifiOverlayM2012K11AC \
    WifiOverlayM2012K11AG \
    WifiOverlayM2012K11AI \
    WifiResTarget

# Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Phantom process monitoring
PRODUCT_PRODUCT_PROPERTIES += \
    sys.fflag.override.settings_enable_monitor_phantom_procs=false

# Platform
TARGET_BOARD_PLATFORM := kona

# QCRIL
PRODUCT_PACKAGES += \
    android.hardware.radio@1.6.vendor \
    android.hardware.radio.config@1.3.vendor \
    android.hardware.radio.deprecated@1.0.vendor \
    android.hardware.secure_element@1.2.vendor \
    android.hardware.wifi.hostapd@1.0.vendor

PRODUCT_SYSTEM_PROPERTIES += \
    persist.vendor.radio.report_codec=1 \
    persist.radio.NO_STAPA=1 \
    persist.radio.VT_HYBRID_ENABLE=1 \
    persist.radio.dynamic_sar=false

PRODUCT_VENDOR_PROPERTIES += \
    persist.radio.multisim.config=dsds \
    persist.vendor.data.mode=concurrent \
    persist.vendor.radio.add_power_save=1 \
    persist.vendor.radio.apm_sim_not_pwdn=1 \
    persist.vendor.radio.atfwd.start=true \
    persist.vendor.radio.cdma_cap=true \
    persist.vendor.radio.custom_ecc=1 \
    persist.vendor.radio.data_con_rprt=1 \
    persist.vendor.radio.data_ltd_sys_ind=1 \
    persist.vendor.radio.dynamic_sar=1 \
    persist.vendor.radio.enable_temp_dds=true \
    persist.vendor.radio.enableadvancedscan=true \
    persist.vendor.radio.force_ltd_sys_ind=1 \
    persist.vendor.radio.force_on_dc=true \
    persist.vendor.radio.manual_nw_rej_ct=1 \
    persist.vendor.radio.mbn_cdma=/vendor/firmware_mnt/image/modem_pr/mcfg/configs/mcfg_sw/oem_sw_j11.txt \
    persist.vendor.radio.procedure_bytes=SKIP \
    persist.vendor.radio.rat_on=combine \
    persist.vendor.radio.redir_party_num=1 \
    persist.vendor.radio.sib16_support=1

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.ipsec_tunnel_migration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnel_migration.xml

# ION
$(call soong_config_set_bool,libion,legacy_impl,true)

# QMI
PRODUCT_PACKAGES += \
    libjson

# QTI
TARGET_COMMON_QTI_COMPONENTS := \
    adreno \
    alarm \
    audio \
    av \
    bt \
    charging \
    display \
    gps \
    init \
    keymaster \
    media \
    overlay \
    perf \
    telephony \
    usb \
    wfd \
    wlan

TARGET_NFC_SKU := pro

# RCS
PRODUCT_PROPERTY_OVERRIDES += \
    persist.rcs.supported=1

# Persistent logcat: keep a rotating logcat in /data/misc/logd so a failed boot
# can be diagnosed from recovery (adb pull /data/misc/logd). Small footprint.
# NOTE: must be PRODUCT_SYSTEM_PROPERTIES — PRODUCT_PROPERTY_OVERRIDES lands in
# /vendor/build.prop on this tree, where vendor_init lacks set permission on
# logpersistd_logging_prop (system_public_prop). That produced 4 AVC denials.
PRODUCT_SYSTEM_PROPERTIES += \
    persist.logd.logpersistd=logcatd \
    persist.logd.logpersistd.size=16 \
    persist.logd.logpersistd.rotate_kbytes=2048 \
    persist.logd.logpersistd.buffer=all

# RmNet Data
PRODUCT_SYSTEM_PROPERTIES += \
    persist.rmnet.data.enable=true \
    persist.data.wda.enable=true \
    persist.data.df.dl_mode=5 \
    persist.data.df.ul_mode=5 \
    persist.data.df.agg.dl_pkt=10 \
    persist.data.df.agg.dl_size=4096 \
    persist.data.df.mux_count=8 \
    persist.data.df.iwlan_mux=9 \
    persist.data.df.dev_name=rmnet_usb0

# Sensors
PRODUCT_VENDOR_PROPERTIES += \
    persist.vendor.sensors.allow_non_default_discovery=true \
    persist.vendor.sensors.sync_request=true

PRODUCT_SYSTEM_EXT_PROPERTIES += \
    persist.vendor.sensors.enable.mag_filter=true

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepdetector.xml

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/sensors/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/hals.conf

PRODUCT_PACKAGES += \
    android.hardware.sensors@1.0-impl-xiaomi \
    android.hardware.sensors@1.0-service \
    libsensorndkbridge

# Shipping API
PRODUCT_SHIPPING_API_LEVEL := 30

# SoC Property
PRODUCT_VENDOR_PROPERTIES += \
    ro.soc.model=SM8250-AC

# Storage
PRODUCT_VENDOR_PROPERTIES += \
    ro.incremental.enable=yes

PRODUCT_PRODUCT_PROPERTIES += \
    persist.sys.fuse.passthrough.enable=true

# Thermal
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/thermal/thermal-india-mgame.conf:$(TARGET_COPY_OUT_VENDOR)/etc/thermal-india-mgame.conf \
    $(LOCAL_PATH)/configs/thermal/thermal-india-tgame.conf:$(TARGET_COPY_OUT_VENDOR)/etc/thermal-india-tgame.conf \
    $(LOCAL_PATH)/configs/thermal/thermal-mgame.conf:$(TARGET_COPY_OUT_VENDOR)/etc/thermal-mgame.conf \
    $(LOCAL_PATH)/configs/thermal/thermal-tgame.conf:$(TARGET_COPY_OUT_VENDOR)/etc/thermal-tgame.conf

PRODUCT_VENDOR_PROPERTIES += \
    vendor.sys.thermal.data.path=/data/vendor/thermal/

# Update Engine
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

# USB
PRODUCT_HAS_GADGET_HAL := true

# Vendor
$(call inherit-product, vendor/xiaomi/alioth/alioth-vendor.mk)

# Verified Boot
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml

# Vibrator
$(call inherit-product, hardware/xiaomi/aidl/vibrator/vibrator-vendor-product.mk)

# VNDK
PRODUCT_PACKAGES += \
    android.hardware.drm@1.4.vendor

# WLAN
PRODUCT_PACKAGES += \
    firmware_WCNSS_qcom_cfg.ini_symlink \
    firmware_wlan_mac.bin_symlink

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/wlan/WCNSS_qcom_cfg_qca6390.ini:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/WCNSS_qcom_cfg.ini

# WFD
PRODUCT_PACKAGES += \
    libwfdaac_vendor:32
