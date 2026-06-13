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
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

class AutoClickerOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var edgeButton: View? = null
    private var panelLayout: LinearLayout? = null
    private var edgeParams: WindowManager.LayoutParams? = null
    private var panelParams: WindowManager.LayoutParams? = null
    private val handler = Handler(Looper.getMainLooper())
    private var isPanelOpen = false

    private var cps = 10
    private var pointCount = 1
    private var intervalMs = 100
    private var touchPoints: List<FloatArray> = listOf()

    private val ACTION_STOP_OVERLAY = "com.example.admin_sensi_booster.STOP_AC_OVERLAY"

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_STOP_OVERLAY) stopSelf()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        cps = intent?.getIntExtra("cps", 10) ?: 10
        pointCount = intent?.getIntExtra("pointCount", 1) ?: 1
        intervalMs = intent?.getIntExtra("interval", 100) ?: 100

        // Parse touch points from intent
        val xList = intent?.getDoubleArrayExtra("xList")?.toList() ?: listOf(540.0)
        val yList = intent?.getDoubleArrayExtra("yList")?.toList() ?: listOf(960.0)
        touchPoints = (0 until minOf(xList.size, yList.size)).map { i ->
            floatArrayOf(xList[i].toFloat(), yList[i].toFloat())
        }

        createNotification()

        if (edgeButton != null) {
            try { windowManager?.removeView(edgeButton) } catch (e: Exception) {}
            try { windowManager?.removeView(panelLayout) } catch (e: Exception) {}
            try { unregisterReceiver(stopReceiver) } catch (e: Exception) {}
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopReceiver, IntentFilter(ACTION_STOP_OVERLAY), Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopReceiver, IntentFilter(ACTION_STOP_OVERLAY))
        }
        setupEdgeButton()
        setupPanel()
        return START_NOT_STICKY
    }

    private fun createNotification() {
        val channelId = "autoclicker_overlay"
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(NotificationChannel(channelId, "Auto Clicker Panel", NotificationManager.IMPORTANCE_LOW))
        }
        val stopIntent = Intent(ACTION_STOP_OVERLAY)
        val pendingStop = PendingIntent.getBroadcast(this, 0, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Auto Clicker Panel Active")
            .setContentText("Tap the side icon to control")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .addAction(android.R.drawable.ic_delete, "Close", pendingStop)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        startForeground(1003, notification)
    }

    private fun setupEdgeButton() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val density = resources.displayMetrics.density

        // Small edge handle on right side
        val btn = FrameLayout(this)
        val btnSize = (48 * density).toInt()
        val bg = GradientDrawable()
        bg.shape = GradientDrawable.RECTANGLE
        bg.cornerRadius = 8 * density
        bg.setColor(Color.parseColor("#CC151619"))
        bg.setStroke((1.5 * density).toInt(), Color.parseColor("#4ADE80"))
        btn.background = bg
        btn.setPadding((6 * density).toInt(), 0, (6 * density).toInt(), 0)

        val icon = ImageView(this)
        icon.setImageResource(android.R.drawable.ic_media_play)
        icon.setColorFilter(Color.parseColor("#4ADE80"))
        val iconParams = FrameLayout.LayoutParams(
            (22 * density).toInt(), (22 * density).toInt(),
            Gravity.CENTER
        )
        btn.addView(icon, iconParams)

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else WindowManager.LayoutParams.TYPE_PHONE

        edgeParams = WindowManager.LayoutParams(
            btnSize, (60 * density).toInt(),
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        edgeParams?.gravity = Gravity.TOP or Gravity.START
        edgeParams?.x = resources.displayMetrics.widthPixels - btnSize
        edgeParams?.y = resources.displayMetrics.heightPixels / 3

        edgeButton = btn
        setupEdgeDrag()
        try { windowManager?.addView(btn, edgeParams) } catch (e: Exception) { e.printStackTrace() }
    }

    private fun setupEdgeDrag() {
        edgeButton?.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f
            private var isDrag = false

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = edgeParams?.x ?: 0
                        initialY = edgeParams?.y ?: 0
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        isDrag = false
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.rawX - initialTouchX
                        val dy = event.rawY - initialTouchY
                        if (Math.abs(dx) > 10 || Math.abs(dy) > 10) isDrag = true
                        edgeParams?.x = initialX + dx.toInt()
                        edgeParams?.y = initialY + dy.toInt()
                        try { windowManager?.updateViewLayout(edgeButton, edgeParams) } catch (e: Exception) {}
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (!isDrag) togglePanel()
                        return true
                    }
                }
                return false
            }
        })
    }

    private fun setupPanel() {
        val density = resources.displayMetrics.density
        val screenWidth = resources.displayMetrics.widthPixels

        panelLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding((14 * density).toInt(), (14 * density).toInt(), (14 * density).toInt(), (14 * density).toInt())
            val bg = GradientDrawable()
            bg.cornerRadius = 14 * density
            bg.setColor(Color.parseColor("#EE111215"))
            bg.setStroke((1 * density).toInt(), Color.parseColor("#334ADE80"))
            background = bg
        }

        // Title
        val title = TextView(this).apply {
            text = "AUTO CLICKER"
            setTextColor(Color.parseColor("#4ADE80"))
            textSize = 11f
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        panelLayout?.addView(title)

        // Status
        val statusRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, (8 * density).toInt(), 0, 0) }
        val statusDot = View(this).apply {
            val s = (6 * density).toInt()
            layoutParams = LinearLayout.LayoutParams(s, s).apply { marginEnd = (6 * density).toInt() }
            val d = GradientDrawable(); d.shape = GradientDrawable.OVAL
            val running = AutoClickerService.isRunning
            d.setColor(if (running) Color.parseColor("#4ADE80") else Color.parseColor("#64748B"))
            background = d
        }
        val statusText = TextView(this).apply {
            text = if (AutoClickerService.isRunning) "RUNNING" else "STOPPED"
            setTextColor(if (AutoClickerService.isRunning) Color.parseColor("#4ADE80") else Color.parseColor("#94A3B8"))
            textSize = 10f; setTypeface(null, android.graphics.Typeface.BOLD)
        }
        statusRow.addView(statusDot); statusRow.addView(statusText)
        panelLayout?.addView(statusRow)

        // Info
        val info = TextView(this).apply {
            text = "$cps CPS \u2022 $pointCount point(s)"
            setTextColor(Color.parseColor("#94A3B8"))
            textSize = 9f
            setPadding(0, (4 * density).toInt(), 0, 0)
        }
        panelLayout?.addView(info)

        // Start button
        val startBtn = makeButton("START", Color.parseColor("#4ADE80"), Color.parseColor("#0A0B0D")) {
            val service = AutoClickerService.instance
            if (service != null) {
                if (touchPoints.isNotEmpty()) {
                    service.startClicking(intervalMs.toLong(), touchPoints)
                } else {
                    service.startClicking(AutoClickerService.lastInterval, AutoClickerService.lastPoints)
                }
                updatePanelStatus()
            }
        }
        panelLayout?.addView(startBtn)

        // Stop button
        val stopBtn = makeButton("STOP", Color.parseColor("#EF4444"), Color.parseColor("#FFFFFF")) {
            AutoClickerService.instance?.stopClicking()
            updatePanelStatus()
        }
        panelLayout?.addView(stopBtn)

        // Close overlay button
        val closeBtn = makeButton("CLOSE PANEL", Color.parseColor("#64748B"), Color.parseColor("#FFFFFF")) {
            stopSelf()
        }
        panelLayout?.addView(closeBtn)

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else WindowManager.LayoutParams.TYPE_PHONE

        panelParams = WindowManager.LayoutParams(
            (200 * density).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        panelParams?.gravity = Gravity.TOP or Gravity.START
        panelParams?.x = screenWidth - (210 * density).toInt()
        panelParams?.y = edgeParams?.y ?: 200

        try { windowManager?.addView(panelLayout, panelParams) } catch (e: Exception) {}
        panelLayout?.visibility = View.GONE
    }

    private fun makeButton(text: String, bgColor: Int, textColor: Int, onClick: () -> Unit): View {
        val density = resources.displayMetrics.density
        val btn = TextView(this).apply {
            this.text = text
            setTextColor(textColor)
            textSize = 10f
            setTypeface(null, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, (8 * density).toInt(), 0, (8 * density).toInt())
        }
        val bg = GradientDrawable()
        bg.cornerRadius = 8 * density
        bg.setColor(bgColor)
        btn.background = bg
        val params = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = (6 * density).toInt() }
        btn.layoutParams = params
        btn.setOnClickListener { onClick() }
        return btn
    }

    private fun updatePanelStatus() {
        try { windowManager?.removeView(panelLayout) } catch (e: Exception) {}
        try { windowManager?.removeView(edgeButton) } catch (e: Exception) {}
        setupEdgeButton()
        setupPanel()
        if (isPanelOpen) panelLayout?.visibility = View.VISIBLE
    }

    private fun togglePanel() {
        if (isPanelOpen) {
            panelLayout?.visibility = View.GONE
            isPanelOpen = false
        } else {
            panelLayout?.visibility = View.VISIBLE
            isPanelOpen = true
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try { windowManager?.removeView(edgeButton) } catch (e: Exception) {}
        try { windowManager?.removeView(panelLayout) } catch (e: Exception) {}
        edgeButton = null; panelLayout = null; windowManager = null
        try { unregisterReceiver(stopReceiver) } catch (e: Exception) {}
    }
}
