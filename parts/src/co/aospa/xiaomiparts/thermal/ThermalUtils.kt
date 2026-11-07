/*
 * Copyright (C) 2020 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */
package co.aospa.xiaomiparts.thermal

import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.os.RemoteException
import android.util.Log
import android.view.Display
import co.aospa.xiaomiparts.touchsampling.TouchSamplingUtils
import co.aospa.xiaomiparts.utils.PartsPreferences
import vendor.xiaomi.hardware.touchfeature.V1_0.ITouchFeature

/**
 * Per-app touch profile helper. Thermal policy itself is owned by the vendor
 * mi_thermald daemon; this class must never write the thermal sconfig node.
 */
class ThermalUtils(context: Context) {
    companion object {
        @JvmStatic
        fun startService(context: Context) {
            context.startService(Intent(context, ThermalService::class.java))
        }

        private fun touchFeature(): ITouchFeature? =
            try {
                ITouchFeature.getService()
            } catch (error: Exception) {
                Log.d("ThermalUtils", "Touch HAL unavailable", error)
                null
            }
    }

    private val app = context.applicationContext
    private val prefs = PartsPreferences.getDefaultSharedPreferences(app)
    private val display =
        app.getSystemService(DisplayManager::class.java)?.getDisplay(Display.DEFAULT_DISPLAY)
    private var hal = touchFeature()
    private var touchChanged = false

    fun applyTouchProfile(packageName: String): Boolean {
        updateTouchModes(packageName)
        return true
    }

    private fun updateTouchModes(packageName: String) {
        if (AliothTouchProfile.isSupported() && TouchSamplingUtils.isEnabled(app)) {
            touchChanged = false
            return
        }
        val saved = prefs.getString(packageName, null)
        resetTouchModes()
        if (saved.isNullOrEmpty()) return
        val values = saved.split(',').map { it.toIntOrNull() }
        if (values.size != 4 || values.any { it == null }) return
        if (hal == null) hal = touchFeature()
        val touch = hal ?: return
        val game = values[0]!!
        val response = values[1]!!
        val sensitivity = values[2]!!
        val edge = values[3]!!
        val active =
            if (AliothTouchProfile.isSupported()) game
            else if (response != 0 && sensitivity != 0 && edge != 0) 1 else 0
        try {
            if (AliothTouchProfile.isSupported()) {
                AliothTouchProfile.applyMode(touch, Constants.MODE_TOUCH_TOLERANCE, sensitivity)
                AliothTouchProfile.applyMode(touch, Constants.MODE_TOUCH_UP_THRESHOLD, response)
            } else {
                touch.setTouchMode(Constants.MODE_TOUCH_TOLERANCE, sensitivity)
                touch.setTouchMode(Constants.MODE_TOUCH_UP_THRESHOLD, response)
            }
            touch.setTouchMode(Constants.MODE_TOUCH_EDGE_FILTER, edge)
            touch.setTouchMode(Constants.MODE_TOUCH_GAME_MODE, game)
            touch.setTouchMode(Constants.MODE_TOUCH_ACTIVE_MODE, active)
            if (game == 1) AliothTouchProfile.apply(touch, prefs, packageName)
            touchChanged = true
            updateTouchRotation()
        } catch (error: RemoteException) {
            Log.w("ThermalUtils", "Cannot apply touch profile", error)
            resetBestEffort()
            hal = null
            touchChanged = false
        }
    }

    private fun resetBestEffort() {
        val modes = mutableListOf(0, 1, 2, 3, 7, 8)
        if (AliothTouchProfile.isSupported()) modes.addAll(listOf(4, 5, 6))
        modes.forEach {
            try {
                hal?.resetTouchMode(it)
            } catch (error: RemoteException) {
                Log.d("ThermalUtils", "Cannot reset touch mode $it", error)
            }
        }
    }

    fun resetTouchModes() {
        if (!touchChanged) return
        if (!(AliothTouchProfile.isSupported() && TouchSamplingUtils.isEnabled(app)))
            resetBestEffort()
        touchChanged = false
    }

    fun updateTouchRotation() {
        if (!touchChanged || display == null || hal == null) return
        try {
            hal?.setTouchMode(Constants.MODE_TOUCH_ROTATION, display.rotation)
        } catch (error: RemoteException) {
            Log.w("ThermalUtils", "Cannot update touch rotation", error)
            hal = null
            touchChanged = false
        }
    }
}
