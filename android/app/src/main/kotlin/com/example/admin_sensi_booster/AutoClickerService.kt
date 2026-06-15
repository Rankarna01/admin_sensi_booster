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
        isBursting = false
        clickRunnable?.let { handler.removeCallbacks(it) }
        clickRunnable = null
    }

    private var isBursting = false

    fun burstClick(intervalMs: Long, points: List<FloatArray>, count: Int, onComplete: () -> Unit) {
        stopClicking()
        if (points.isEmpty() || count <= 0 || Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            onComplete()
            return
        }

        touchPoints = points
        currentPointIndex = 0
        isRunning = true
        isBursting = true

        fireNextBurst(0, count, onComplete)
    }

    private fun fireNextBurst(clicksDone: Int, total: Int, onComplete: () -> Unit) {
        if (!isRunning || !isBursting || clicksDone >= total) {
            stopClicking()
            onComplete()
            return
        }

        val point = touchPoints[currentPointIndex % touchPoints.size]
        currentPointIndex++

        val path = Path()
        path.moveTo(point[0], point[1])

        // 10ms stroke is extremely fast but valid
        val stroke = GestureDescription.StrokeDescription(path, 0L, 10L)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                super.onCompleted(gestureDescription)
                fireNextBurst(clicksDone + 1, total, onComplete)
            }
            override fun onCancelled(gestureDescription: GestureDescription?) {
                super.onCancelled(gestureDescription)
                // Even if cancelled, we try to push the next one to complete the burst
                fireNextBurst(clicksDone + 1, total, onComplete)
            }
        }, null)
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
