package com.example.admin_sensi_booster

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AutoClickerService : AccessibilityService() {

    companion object {
        var instance: AutoClickerService? = null
            private set

        // Shared state (read by Flutter via MethodChannel)
        var isRunning: Boolean = false
            private set

        // Store last settings so overlay can reuse
        var lastInterval: Long = 100L
            private set
        var lastPoints: List<FloatArray> = listOf(floatArrayOf(540f, 960f))
            private set
    }

    private val handler = Handler(Looper.getMainLooper())
    private var clickInterval: Long = 100L // ms between clicks
    private var touchPoints: List<FloatArray> = listOf(floatArrayOf(540f, 960f)) // [x, y] pairs
    private var currentPointIndex = 0
    private var clickRunnable: Runnable? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("AutoClicker", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not used - we only use gesture dispatch
    }

    override fun onInterrupt() {
        stopClicking()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopClicking()
        instance = null
    }

    fun startClicking(intervalMs: Long, points: List<FloatArray>) {
        stopClicking()
        if (points.isEmpty()) return

        clickInterval = intervalMs.coerceAtLeast(10L)
        touchPoints = points
        lastInterval = clickInterval
        lastPoints = points
        currentPointIndex = 0
        isRunning = true

        clickRunnable = object : Runnable {
            override fun run() {
                if (!isRunning) return
                performClick()
                handler.postDelayed(this, clickInterval)
            }
        }
        handler.post(clickRunnable!!)
    }

    fun stopClicking() {
        isRunning = false
        clickRunnable?.let { handler.removeCallbacks(it) }
        clickRunnable = null
    }

    fun updateSettings(intervalMs: Long, points: List<FloatArray>) {
        clickInterval = intervalMs.coerceAtLeast(10L)
        touchPoints = points
    }

    private fun performClick() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        if (touchPoints.isEmpty()) return

        // Cycle through touch points
        val point = touchPoints[currentPointIndex % touchPoints.size]
        currentPointIndex++

        val path = Path()
        path.moveTo(point[0], point[1])

        val stroke = GestureDescription.StrokeDescription(path, 0L, 30L)
        val gesture = GestureDescription.Builder()
            .addStroke(stroke)
            .build()

        dispatchGesture(gesture, null, null)
    }
}
