package com.example.admin_sensi_booster

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import androidx.core.app.NotificationCompat

class CrosshairOverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var crosshairView: CrosshairView
    private val handler = Handler(Looper.getMainLooper())

    private var crosshairShape = "cross_dot"   // dot, cross, cross_dot, circle, t_shape, diamond, plus_circle, scope
    private var crosshairColor = "#FF0000"      // Hex color
    private var crosshairSize = 40              // Size in dp
    private var crosshairOpacity = 255          // 0-255
    private var offsetX = 0                     // Horizontal offset from center
    private var offsetY = 0                     // Vertical offset from center
    private var isVisible = true                // Toggle visibility

    private val ACTION_STOP_CROSSHAIR = "com.example.admin_sensi_booster.STOP_CROSSHAIR"

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_STOP_CROSSHAIR) stopSelf()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Read settings from intent
        crosshairShape = intent?.getStringExtra("shape") ?: "cross_dot"
        crosshairColor = intent?.getStringExtra("color") ?: "#FF0000"
        crosshairSize = intent?.getIntExtra("size", 40) ?: 40
        crosshairOpacity = intent?.getIntExtra("opacity", 255) ?: 255
        offsetX = intent?.getIntExtra("offsetX", 0) ?: 0
        offsetY = intent?.getIntExtra("offsetY", 0) ?: 0
        isVisible = true

        createNotificationAndStartForeground()

        if (::crosshairView.isInitialized) {
            try { windowManager.removeView(crosshairView) } catch (e: Exception) {}
            try { unregisterReceiver(stopReceiver) } catch (e: Exception) {}
        }

        registerReceiver(stopReceiver, IntentFilter(ACTION_STOP_CROSSHAIR))
        setupCrosshairView()
        return START_NOT_STICKY
    }

    // Called to update crosshair settings while service is running
    fun updateSettings(shape: String, color: String, size: Int, opacity: Int, offX: Int, offY: Int) {
        crosshairShape = shape
        crosshairColor = color
        crosshairSize = size
        crosshairOpacity = opacity
        offsetX = offX
        offsetY = offY
        if (::crosshairView.isInitialized) crosshairView.invalidate()
    }

    private fun createNotificationAndStartForeground() {
        val channelId = "crosshair_overlay"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Crosshair Overlay", NotificationManager.IMPORTANCE_LOW)
            notificationManager.createNotificationChannel(channel)
        }

        val stopIntent = Intent(ACTION_STOP_CROSSHAIR)
        val pendingStop = PendingIntent.getBroadcast(this, 0, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Crosshair Overlay Active")
            .setContentText("Double-tap crosshair to toggle on/off")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .addAction(android.R.drawable.ic_delete, "Stop", pendingStop)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(1002, notification)
    }

    private fun setupCrosshairView() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        crosshairView = CrosshairView(this)

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.START
        params.x = 0
        params.y = 0

        try {
            windowManager.addView(crosshairView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::crosshairView.isInitialized) {
            try { windowManager.removeView(crosshairView) } catch (e: Exception) {}
            try { unregisterReceiver(stopReceiver) } catch (e: Exception) {}
        }
    }

    // ====================================================================
    // INNER VIEW: Draws the crosshair + handles double-tap to toggle
    // ====================================================================
    inner class CrosshairView(context: Context) : View(context) {

        private val paint = Paint().apply {
            isAntiAlias = true
            style = Paint.Style.FILL_AND_STROKE
            strokeCap = Paint.Cap.ROUND
        }

        private val outlinePaint = Paint().apply {
            isAntiAlias = true
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
        }

        // Double-tap detection
        private var lastTapTime: Long = 0
        private val DOUBLE_TAP_THRESHOLD = 300L

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            if (!isVisible) return

            val color = try { Color.parseColor(crosshairColor) } catch (e: Exception) { Color.RED }
            paint.color = color
            paint.alpha = crosshairOpacity
            outlinePaint.color = color
            outlinePaint.alpha = (crosshairOpacity * 0.4).toInt()

            val centerX = (width / 2f) + (offsetX * resources.displayMetrics.density)
            val centerY = (height / 2f) + (offsetY * resources.displayMetrics.density)
            val size = crosshairSize * resources.displayMetrics.density
            val strokeWidth = (size * 0.08f).coerceAtLeast(2f)

            paint.strokeWidth = strokeWidth
            outlinePaint.strokeWidth = strokeWidth * 2.5f

            when (crosshairShape) {
                "dot" -> drawDot(canvas, centerX, centerY, size)
                "cross" -> drawCross(canvas, centerX, centerY, size)
                "cross_dot" -> { drawCross(canvas, centerX, centerY, size); drawDot(canvas, centerX, centerY, size * 0.25f) }
                "circle" -> drawCircleShape(canvas, centerX, centerY, size)
                "t_shape" -> drawTShape(canvas, centerX, centerY, size)
                "diamond" -> drawDiamond(canvas, centerX, centerY, size)
                "plus_circle" -> drawPlusCircle(canvas, centerX, centerY, size)
                "scope" -> drawScope(canvas, centerX, centerY, size)
                else -> { drawCross(canvas, centerX, centerY, size); drawDot(canvas, centerX, centerY, size * 0.25f) }
            }
        }

        private fun drawDot(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            canvas.drawCircle(cx, cy, size * 0.15f, paint)
        }

        private fun drawCross(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val half = size * 0.5f
            val gap = size * 0.12f
            // Outline (glow effect)
            canvas.drawLine(cx - half, cy, cx - gap, cy, outlinePaint)
            canvas.drawLine(cx + gap, cy, cx + half, cy, outlinePaint)
            canvas.drawLine(cx, cy - half, cx, cy - gap, outlinePaint)
            canvas.drawLine(cx, cy + gap, cx, cy + half, outlinePaint)
            // Main lines
            canvas.drawLine(cx - half, cy, cx - gap, cy, paint)
            canvas.drawLine(cx + gap, cy, cx + half, cy, paint)
            canvas.drawLine(cx, cy - half, cx, cy - gap, paint)
            canvas.drawLine(cx, cy + gap, cx, cy + half, paint)
        }

        private fun drawCircleShape(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            canvas.drawCircle(cx, cy, size * 0.4f, outlinePaint)
            paint.style = Paint.Style.STROKE
            canvas.drawCircle(cx, cy, size * 0.4f, paint)
            paint.style = Paint.Style.FILL_AND_STROKE
            canvas.drawCircle(cx, cy, size * 0.06f, paint)
        }

        private fun drawTShape(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val half = size * 0.5f
            // Horizontal line
            canvas.drawLine(cx - half, cy - half * 0.3f, cx + half, cy - half * 0.3f, outlinePaint)
            canvas.drawLine(cx - half, cy - half * 0.3f, cx + half, cy - half * 0.3f, paint)
            // Vertical line down
            canvas.drawLine(cx, cy - half * 0.3f, cx, cy + half, outlinePaint)
            canvas.drawLine(cx, cy - half * 0.3f, cx, cy + half, paint)
            // Center dot
            canvas.drawCircle(cx, cy + half * 0.1f, size * 0.06f, paint)
        }

        private fun drawDiamond(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val half = size * 0.35f
            val path = Path()
            path.moveTo(cx, cy - half)
            path.lineTo(cx + half, cy)
            path.lineTo(cx, cy + half)
            path.lineTo(cx - half, cy)
            path.close()
            canvas.drawPath(path, outlinePaint)
            paint.style = Paint.Style.STROKE
            canvas.drawPath(path, paint)
            paint.style = Paint.Style.FILL_AND_STROKE
            canvas.drawCircle(cx, cy, size * 0.06f, paint)
        }

        private fun drawPlusCircle(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val r = size * 0.35f
            // Outer circle
            paint.style = Paint.Style.STROKE
            canvas.drawCircle(cx, cy, r, paint)
            paint.style = Paint.Style.FILL_AND_STROKE
            // Inner cross
            val inner = r * 0.5f
            canvas.drawLine(cx - inner, cy, cx + inner, cy, paint)
            canvas.drawLine(cx, cy - inner, cx, cy + inner, paint)
            // Center dot
            canvas.drawCircle(cx, cy, size * 0.05f, paint)
        }

        private fun drawScope(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val r = size * 0.45f
            val gap = size * 0.15f
            // Outer circle
            paint.style = Paint.Style.STROKE
            canvas.drawCircle(cx, cy, r, paint)
            // Tick marks (top, bottom, left, right)
            canvas.drawLine(cx, cy - r, cx, cy - r + gap, paint)
            canvas.drawLine(cx, cy + r, cx, cy + r - gap, paint)
            canvas.drawLine(cx - r, cy, cx - r + gap, cy, paint)
            canvas.drawLine(cx + r, cy, cx + r - gap, cy, paint)
            paint.style = Paint.Style.FILL_AND_STROKE
            // Center dot
            canvas.drawCircle(cx, cy, size * 0.05f, paint)
        }

        override fun onTouchEvent(event: MotionEvent): Boolean {
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    val now = System.currentTimeMillis()
                    if (now - lastTapTime < DOUBLE_TAP_THRESHOLD) {
                        // Double-tap detected: toggle visibility
                        isVisible = !isVisible
                        invalidate()
                        lastTapTime = 0
                    } else {
                        lastTapTime = now
                    }
                    return true
                }
            }
            return super.onTouchEvent(event)
        }
    }
}
