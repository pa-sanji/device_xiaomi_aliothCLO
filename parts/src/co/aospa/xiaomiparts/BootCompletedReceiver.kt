/*
 * Copyright (C) 2015 The CyanogenMod Project
 *               2017-2020 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * SPDX-License-Identifier: Apache-2.0
 */

package co.aospa.xiaomiparts

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import co.aospa.xiaomiparts.misound.MiSoundUtils
import co.aospa.xiaomiparts.display.DisplayUtils
import co.aospa.xiaomiparts.refreshrate.RefreshUtils
import co.aospa.xiaomiparts.thermal.ThermalUtils
import co.aospa.xiaomiparts.touchsampling.TouchSamplingUtils

class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_LOCKED_BOOT_COMPLETED) return
        try {
            MiSoundUtils.getInstance(context)
        } catch (error: RuntimeException) {
            Log.w("XiaomiParts", "Cannot initialize MiSound", error)
        }
        ThermalUtils.startService(context)
        RefreshUtils.startService(context)
        TouchSamplingUtils.restoreSamplingValue(context)
        DisplayUtils.restore(context)
    }
}
