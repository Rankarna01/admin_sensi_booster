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
import android.os.IBinder
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import androidx.core.app.NotificationCompat

class CrosshairOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var crosshairView: CrosshairView? = null

    private var crosshairShape = "cross_dot"
    private var crosshairColor = "#FF0000"
    private var crosshairSize = 40
    private var crosshairOpacity = 255
    private var offsetX = 0
    private var offsetY = 0

    private val ACTION_STOP_CROSSHAIR = "com.example.admin_sensi_booster.STOP_CROSSHAIR"

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_STOP_CROSSHAIR) stopSelf()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val shape = intent?.getStringExtra("shape") ?: crosshairShape
        val color = intent?.getStringExtra("color") ?: crosshairColor
        val size = intent?.getIntExtra("size", crosshairSize) ?: crosshairSize
        val opacity = intent?.getIntExtra("opacity", crosshairOpacity) ?: crosshairOpacity
        val offX = intent?.getIntExtra("offsetX", offsetX) ?: offsetX
        val offY = intent?.getIntExtra("offsetY", offsetY) ?: offsetY

        crosshairShape = shape
        crosshairColor = color
        crosshairSize = size
        crosshairOpacity = opacity
        offsetX = offX
        offsetY = offY

        // If view already exists, just update it (don't recreate)
        if (crosshairView != null) {
            crosshairView?.updateSettings()
            return START_NOT_STICKY
        }

        // First time setup
        createNotificationAndStartForeground()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopReceiver, IntentFilter(ACTION_STOP_CROSSHAIR), Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopReceiver, IntentFilter(ACTION_STOP_CROSSHAIR))
        }
        setupCrosshairView()
        return START_NOT_STICKY
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
            .setContentText("Tap Stop or use app to deactivate")
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

        // FLAG_NOT_TOUCHABLE = zero touch interception = zero game lag
        // FLAG_LAYOUT_NO_LIMITS = extends overlay into system bar areas (critical for full-screen games)
        // FLAG_LAYOUT_IN_SCREEN = layout within entire screen
        // FLAG_HARDWARE_ACCELERATED = GPU compositing with game surfaces
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.RGBA_8888
        )

        // Cover entire screen including cutout/notch areas
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            params.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        params.gravity = Gravity.TOP or Gravity.START

        try {
            windowManager?.addView(crosshairView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            crosshairView?.let { windowManager?.removeView(it) }
        } catch (e: Exception) {}
        crosshairView = null
        windowManager = null
        try { unregisterReceiver(stopReceiver) } catch (e: Exception) {}
    }

    // ====================================================================
    // LIGHTWEIGHT CROSSHAIR VIEW
    // - Uses hardware layer for GPU-accelerated rendering
    // - Caches all calculations to avoid GC pressure
    // - Does NOT intercept touches (FLAG_NOT_TOUCHABLE on parent)
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

        private var cachedColor: Int = Color.RED
        private var cachedAlpha: Int = 255
        private var cachedOutlineAlpha: Int = 102
        private var cachedCenterX: Float = 0f
        private var cachedCenterY: Float = 0f
        private var cachedSize: Float = 0f
        private var cachedStrokeWidth: Float = 2f
        private var cachedShape: String = "cross_dot"

        init {
            // Use hardware layer for GPU rendering - much faster
            setLayerType(LAYER_TYPE_HARDWARE, null)
            updateSettings()
        }

        fun updateSettings() {
            cachedColor = try { Color.parseColor(crosshairColor) } catch (e: Exception) { Color.RED }
            cachedAlpha = crosshairOpacity
            cachedOutlineAlpha = (crosshairOpacity * 0.4).toInt()
            cachedShape = crosshairShape

            val density = resources.displayMetrics.density
            cachedCenterX = (resources.displayMetrics.widthPixels / 2f) + (offsetX * density)
            cachedCenterY = (resources.displayMetrics.heightPixels / 2f) + (offsetY * density)
            cachedSize = crosshairSize * density
            cachedStrokeWidth = (cachedSize * 0.08f).coerceAtLeast(2f)

            invalidate()
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)

            paint.color = cachedColor
            paint.alpha = cachedAlpha
            paint.strokeWidth = cachedStrokeWidth

            outlinePaint.color = cachedColor
            outlinePaint.alpha = cachedOutlineAlpha
            outlinePaint.strokeWidth = cachedStrokeWidth * 2.5f

            val cx = cachedCenterX
            val cy = cachedCenterY
            val s = cachedSize

            when (cachedShape) {
                "dot" -> drawDot(canvas, cx, cy, s)
                "cross" -> drawCross(canvas, cx, cy, s)
                "cross_dot" -> { drawCross(canvas, cx, cy, s); drawDot(canvas, cx, cy, s * 0.25f) }
                "circle" -> drawCircleShape(canvas, cx, cy, s)
                "t_shape" -> drawTShape(canvas, cx, cy, s)
                "diamond" -> drawDiamond(canvas, cx, cy, s)
                "plus_circle" -> drawPlusCircle(canvas, cx, cy, s)
                "scope" -> drawScope(canvas, cx, cy, s)
                else -> { drawCross(canvas, cx, cy, s); drawDot(canvas, cx, cy, s * 0.25f) }
            }
        }

        private fun drawDot(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            canvas.drawCircle(cx, cy, size * 0.15f, paint)
        }

        private fun drawCross(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val half = size * 0.5f
            val gap = size * 0.12f
            canvas.drawLine(cx - half, cy, cx - gap, cy, outlinePaint)
            canvas.drawLine(cx + gap, cy, cx + half, cy, outlinePaint)
            canvas.drawLine(cx, cy - half, cx, cy - gap, outlinePaint)
            canvas.drawLine(cx, cy + gap, cx, cy + half, outlinePaint)
            canvas.drawLine(cx - half, cy, cx - gap, cy, paint)
            canvas.drawLine(cx + gap, cy, cx + half, cy, paint)
            canvas.drawLine(cx, cy - half, cx, cy - gap, paint)
            canvas.drawLine(cx, cy + gap, cx, cy + half, paint)
        }

        private fun drawCircleShape(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            paint.style = Paint.Style.STROKE
            canvas.drawCircle(cx, cy, size * 0.4f, paint)
            paint.style = Paint.Style.FILL_AND_STROKE
            canvas.drawCircle(cx, cy, size * 0.06f, paint)
        }

        private fun drawTShape(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val half = size * 0.5f
            canvas.drawLine(cx - half, cy - half * 0.3f, cx + half, cy - half * 0.3f, outlinePaint)
            canvas.drawLine(cx - half, cy - half * 0.3f, cx + half, cy - half * 0.3f, paint)
            canvas.drawLine(cx, cy - half * 0.3f, cx, cy + half, outlinePaint)
            canvas.drawLine(cx, cy - half * 0.3f, cx, cy + half, paint)
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
            paint.style = Paint.Style.STROKE
            canvas.drawPath(path, paint)
            paint.style = Paint.Style.FILL_AND_STROKE
            canvas.drawCircle(cx, cy, size * 0.06f, paint)
        }

        private fun drawPlusCircle(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val r = size * 0.35f
            paint.style = Paint.Style.STROKE
            canvas.drawCircle(cx, cy, r, paint)
            paint.style = Paint.Style.FILL_AND_STROKE
            val inner = r * 0.5f
            canvas.drawLine(cx - inner, cy, cx + inner, cy, paint)
            canvas.drawLine(cx, cy - inner, cx, cy + inner, paint)
            canvas.drawCircle(cx, cy, size * 0.05f, paint)
        }

        private fun drawScope(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val r = size * 0.45f
            val gap = size * 0.15f
            paint.style = Paint.Style.STROKE
            canvas.drawCircle(cx, cy, r, paint)
            paint.style = Paint.Style.FILL_AND_STROKE
            canvas.drawLine(cx, cy - r, cx, cy - r + gap, paint)
            canvas.drawLine(cx, cy + r, cx, cy + r - gap, paint)
            canvas.drawLine(cx - r, cy, cx - r + gap, cy, paint)
            canvas.drawLine(cx + r, cy, cx + r - gap, cy, paint)
            canvas.drawCircle(cx, cy, size * 0.05f, paint)
        }
    }
}
