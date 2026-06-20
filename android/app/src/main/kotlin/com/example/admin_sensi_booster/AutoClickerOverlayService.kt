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
import android.widget.Toast
import androidx.core.app.NotificationCompat

class AutoClickerOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var edgeButton: View? = null
    private var panelLayout: LinearLayout? = null
    private var triggerButton: View? = null
    private var edgeParams: WindowManager.LayoutParams? = null
    private var panelParams: WindowManager.LayoutParams? = null
    private var triggerParams: WindowManager.LayoutParams? = null
    private val handler = Handler(Looper.getMainLooper())
    private var isPanelOpen = false

    private var cps = 10
    private var isMapping = false
    private var markerOpacity = 1.0f
    private var isShizukuMode = false

    private val pointMarkers = mutableListOf<FrameLayout>()
    private val markerLayoutParams = mutableListOf<WindowManager.LayoutParams>()
    private var mappingToolbar: LinearLayout? = null
    private var mappingToolbarParams: WindowManager.LayoutParams? = null
    private var mappingCountLabel: TextView? = null

    private var pointCount = 1
    private var intervalMs = 100
    private var touchPoints = mutableListOf<FloatArray>()

    private val layoutType: Int
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

    private val ACTION_STOP_OVERLAY = "com.example.admin_sensi_booster.STOP_AC_OVERLAY"

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_STOP_OVERLAY) stopSelf()
        }
    }

    private var shizukuMacroService: IShizukuMacroService? = null
    private val shizukuConnection = object : android.content.ServiceConnection {
        override fun onServiceConnected(name: android.content.ComponentName?, service: IBinder?) {
            shizukuMacroService = IShizukuMacroService.Stub.asInterface(service)
        }
        override fun onServiceDisconnected(name: android.content.ComponentName?) {
            shizukuMacroService = null
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        cps = intent?.getIntExtra("cps", 10) ?: 10
        pointCount = intent?.getIntExtra("pointCount", 1) ?: 1
        intervalMs = intent?.getIntExtra("interval", 100) ?: 100
        isShizukuMode = intent?.getBooleanExtra("isShizukuMode", false) ?: false

        var xList = intent?.getDoubleArrayExtra("xList")?.toList() ?: emptyList()
        var yList = intent?.getDoubleArrayExtra("yList")?.toList() ?: emptyList()
        
        // If default from Flutter, change it to empty so it doesn't show initially
        if (xList.size == 1 && xList[0] == 540.0 && yList.size == 1 && yList[0] == 960.0) {
            xList = emptyList()
            yList = emptyList()
        }
        
        touchPoints.clear()
        for (i in 0 until minOf(xList.size, yList.size)) {
            touchPoints.add(floatArrayOf(xList[i].toFloat(), yList[i].toFloat()))
        }
        pointCount = touchPoints.size

        createNotification()

        // Clean up any previous views
        cleanupAllViews()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopReceiver, IntentFilter(ACTION_STOP_OVERLAY), Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(stopReceiver, IntentFilter(ACTION_STOP_OVERLAY))
        }

        if (isShizukuMode) {
            try {
                if (rikka.shizuku.Shizuku.pingBinder() && rikka.shizuku.Shizuku.checkSelfPermission() == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    val args = rikka.shizuku.Shizuku.UserServiceArgs(android.content.ComponentName(packageName, ShizukuMacroService::class.java.name))
                        .daemon(false)
                        .processNameSuffix("macro_service")
                        .debuggable(true)
                        .version(1)
                    rikka.shizuku.Shizuku.bindUserService(args, shizukuConnection)
                }
            } catch (e: Exception) {}
        }

        if (windowManager == null) windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        setupEdgeButton()
        setupPanel()
        
        // Initialize existing points directly on screen
        val density = resources.displayMetrics.density
        val markerSize = (48 * density).toInt()
        for (i in touchPoints.indices) {
            addMarkerAtPixel(
                touchPoints[i][0].toInt(),
                touchPoints[i][1].toInt(),
                markerSize,
                density
            )
        }
        
        return START_NOT_STICKY
    }

    private fun cleanupAllViews() {
        exitMappingMode()
        exitMappingMode()
        try { windowManager?.removeView(edgeButton) } catch (_: Exception) {}
        try { windowManager?.removeView(panelLayout) } catch (_: Exception) {}
        for (marker in pointMarkers) {
            try { windowManager?.removeView(marker) } catch (_: Exception) {}
        }
        pointMarkers.clear()
        markerLayoutParams.clear()
        edgeButton = null
        panelLayout = null
        try { unregisterReceiver(stopReceiver) } catch (_: Exception) {}
    }

    // ═══════════════════════════════════════════
    // NOTIFICATION
    // ═══════════════════════════════════════════

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

    // ═══════════════════════════════════════════
    // EDGE BUTTON (floating draggable icon)
    // ═══════════════════════════════════════════

    private fun setupEdgeButton() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val density = resources.displayMetrics.density

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
                        try { windowManager?.updateViewLayout(edgeButton, edgeParams) } catch (_: Exception) {}
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

    // ═══════════════════════════════════════════
    // CONTROL PANEL
    // ═══════════════════════════════════════════

    private fun setupPanel() {
        val density = resources.displayMetrics.density
        val screenWidth = resources.displayMetrics.widthPixels

        panelLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding((14 * density).toInt(), (14 * density).toInt(), (14 * density).toInt(), (14 * density).toInt())
            val panelBg = GradientDrawable()
            panelBg.cornerRadius = 14 * density
            panelBg.setColor(Color.parseColor("#EE111215"))
            panelBg.setStroke((1 * density).toInt(), Color.parseColor("#334ADE80"))
            background = panelBg
        }

        // Title
        val title = TextView(this).apply {
            text = "AUTO CLICKER"
            setTextColor(Color.parseColor("#4ADE80"))
            textSize = 11f
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        panelLayout?.addView(title)

        // We removed the START and STOP buttons here so the user only relies on the HOLD trigger.

        // Opacity slider for Map Points (Key Frames)
        val opacityLabel = TextView(this).apply {
            text = "KEY FRAME OPACITY"
            setTextColor(Color.parseColor("#94A3B8"))
            textSize = 9f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding((4 * density).toInt(), (12 * density).toInt(), 0, (4 * density).toInt())
        }
        panelLayout?.addView(opacityLabel)

        val opacitySlider = android.widget.SeekBar(this).apply {
            max = 100
            progress = (markerOpacity * 100).toInt()
            setOnSeekBarChangeListener(object : android.widget.SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: android.widget.SeekBar?, progress: Int, fromUser: Boolean) {
                    markerOpacity = (progress / 100f).coerceAtLeast(0.1f) // Prevent fully invisible
                    for (marker in pointMarkers) {
                        marker.alpha = markerOpacity
                    }
                }
                override fun onStartTrackingTouch(seekBar: android.widget.SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: android.widget.SeekBar?) {}
            })
        }
        panelLayout?.addView(opacitySlider)

        // ═══ MAP POINTS button ═══
        val mapBtn = makeButton("MAP POINTS", android.R.drawable.ic_dialog_map, Color.parseColor("#3B82F6"), Color.parseColor("#FFFFFF")) {
            enterMappingMode()
        }
        panelLayout?.addView(mapBtn)

        // Hide modal button
        val closeBtn = makeButton("HIDE MODAL", android.R.drawable.ic_menu_close_clear_cancel, Color.parseColor("#64748B"), Color.parseColor("#FFFFFF")) {
            togglePanel()
        }
        panelLayout?.addView(closeBtn)

        // Turn Off Auto Clicker entirely
        val turnOffBtn = makeButton("TURN OFF", android.R.drawable.ic_delete, Color.parseColor("#EF4444"), Color.parseColor("#FFFFFF")) {
            stopSelf()
        }
        panelLayout?.addView(turnOffBtn)

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

        try { windowManager?.addView(panelLayout, panelParams) } catch (_: Exception) {}
        panelLayout?.visibility = View.GONE
    }

    private fun makeButton(text: String, iconResId: Int, bgColor: Int, textColor: Int, onClick: () -> Unit): View {
        val density = resources.displayMetrics.density
        
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, (8 * density).toInt(), 0, (8 * density).toInt())
        }

        val icon = ImageView(this).apply {
            setImageResource(iconResId)
            setColorFilter(textColor)
            layoutParams = LinearLayout.LayoutParams((14 * density).toInt(), (14 * density).toInt()).apply {
                marginEnd = (6 * density).toInt()
            }
        }

        val textView = TextView(this).apply {
            this.text = text
            setTextColor(textColor)
            textSize = 10f
            setTypeface(null, android.graphics.Typeface.BOLD)
        }

        layout.addView(icon)
        layout.addView(textView)

        val bg = GradientDrawable()
        bg.cornerRadius = 8 * density
        bg.setColor(bgColor)
        layout.background = bg
        
        val params = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = (6 * density).toInt() }
        layout.layoutParams = params

        layout.setOnClickListener { onClick() }

        return layout
    }

    private fun togglePanel() {
        if (isMapping) return // Don't toggle panel while mapping
        if (isPanelOpen) {
            panelLayout?.visibility = View.GONE
            isPanelOpen = false
        } else {
            panelLayout?.visibility = View.VISIBLE
            isPanelOpen = true
        }
    }

    private fun refreshPanel() {
        try { windowManager?.removeView(panelLayout) } catch (_: Exception) {}
        // DO NOT recreate edgeButton and triggerButton here, otherwise their positions reset!
        setupPanel()
        if (isPanelOpen) panelLayout?.visibility = View.VISIBLE
    }

    // ═══════════════════════════════════════════
    // KEY MAP / MAPPING MODE
    // ═══════════════════════════════════════════

    private fun enterMappingMode() {
        if (isMapping) return
        isMapping = true

        // Hide panel and edge button
        panelLayout?.visibility = View.GONE
        edgeButton?.visibility = View.GONE
        isPanelOpen = false

        val density = resources.displayMetrics.density

        // Show the mapping toolbar at bottom
        showMappingToolbar(density)
    }

    private fun addMarkerAtPixel(centerX: Int, centerY: Int, markerSize: Int, density: Float) {
        val index = pointMarkers.size
        val marker = createMarkerView(index, density)
        val params = WindowManager.LayoutParams(
            markerSize, markerSize,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        params.x = centerX - markerSize / 2
        params.y = centerY - markerSize / 2

        setupMarkerDrag(marker, index, params)

        pointMarkers.add(marker)
        markerLayoutParams.add(params)
        try { windowManager?.addView(marker, params) } catch (_: Exception) {}
    }

    private fun createMarkerView(index: Int, density: Float): FrameLayout {
        val frame = FrameLayout(this)
        frame.alpha = markerOpacity

        // Outer glow ring
        val outerRing = View(this).apply {
            val ringBg = GradientDrawable()
            ringBg.shape = GradientDrawable.OVAL
            ringBg.setColor(Color.TRANSPARENT)
            ringBg.setStroke((1 * density).toInt(), Color.parseColor("#554ADE80"))
            background = ringBg
        }
        frame.addView(outerRing, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        // Inner circle
        val innerSize = (32 * density).toInt()
        val inner = FrameLayout(this).apply {
            val bg = GradientDrawable()
            bg.shape = GradientDrawable.OVAL
            bg.setColor(Color.parseColor("#AA1A3A2A"))
            bg.setStroke((2 * density).toInt(), Color.parseColor("#4ADE80"))
            background = bg
        }

        // Number label
        val text = TextView(this).apply {
            text = "${index + 1}"
            setTextColor(Color.WHITE)
            textSize = 13f
            setTypeface(null, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
        }
        inner.addView(text, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        val innerParams = FrameLayout.LayoutParams(innerSize, innerSize, Gravity.CENTER)
        frame.addView(inner, innerParams)

        // Crosshair lines
        val lineThick = (1 * density).toInt().coerceAtLeast(1)
        val lineLen = (8 * density).toInt()
        val lineColor = Color.parseColor("#884ADE80")

        // Top line
        val topLine = View(this).apply { setBackgroundColor(lineColor) }
        frame.addView(topLine, FrameLayout.LayoutParams(lineThick, lineLen, Gravity.CENTER_HORIZONTAL or Gravity.TOP))

        // Bottom line
        val botLine = View(this).apply { setBackgroundColor(lineColor) }
        frame.addView(botLine, FrameLayout.LayoutParams(lineThick, lineLen, Gravity.CENTER_HORIZONTAL or Gravity.BOTTOM))

        // Left line
        val leftLine = View(this).apply { setBackgroundColor(lineColor) }
        frame.addView(leftLine, FrameLayout.LayoutParams(lineLen, lineThick, Gravity.START or Gravity.CENTER_VERTICAL))

        // Right line
        val rightLine = View(this).apply { setBackgroundColor(lineColor) }
        frame.addView(rightLine, FrameLayout.LayoutParams(lineLen, lineThick, Gravity.END or Gravity.CENTER_VERTICAL))

        return frame
    }

    private fun setupMarkerDrag(view: View, index: Int, params: WindowManager.LayoutParams) {
        view.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f
            private var isDrag = false

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                if (!isMapping) {
                    // During gameplay, tapping the marker triggers burst fire
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            // Trigger burst
                            if (isShizukuMode && shizukuMacroService != null) {
                                if (touchPoints.isNotEmpty()) {
                                    val inner = (v as? FrameLayout)?.getChildAt(1)
                                    (inner?.background as? GradientDrawable)?.setColor(Color.parseColor("#EEF43F5E"))
                                    params.flags = params.flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                                    try { windowManager?.updateViewLayout(v, params) } catch (_: Exception) {}

                                    shizukuMacroService?.startAutoClick(touchPoints[index][0].toInt(), touchPoints[index][1].toInt(), intervalMs)
                                    val totalDuration = intervalMs * 20L
                                    Handler(Looper.getMainLooper()).postDelayed({
                                        try {
                                            shizukuMacroService?.stopAutoClick()
                                            (inner?.background as? GradientDrawable)?.setColor(Color.parseColor("#AA1A3A2A"))
                                            params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE.inv()
                                            windowManager?.updateViewLayout(v, params)
                                        } catch (_: Exception) {}
                                    }, totalDuration)
                                }
                            } else {
                                val service = AutoClickerService.instance
                                if (service != null && touchPoints.isNotEmpty()) {
                                    // Make marker red and untouchable to let clicks pass through
                                    val inner = (v as? FrameLayout)?.getChildAt(1)
                                    (inner?.background as? GradientDrawable)?.setColor(Color.parseColor("#EEF43F5E")) // Red
                                    
                                    params.flags = params.flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                                    try { windowManager?.updateViewLayout(v, params) } catch (_: Exception) {}

                                    service.burstClick(intervalMs.toLong(), listOf(touchPoints[index]), 20) {
                                        // On complete, restore color and touchability
                                        Handler(Looper.getMainLooper()).post {
                                            (inner?.background as? GradientDrawable)?.setColor(Color.parseColor("#AA1A3A2A")) // Green
                                            params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE.inv()
                                            try { windowManager?.updateViewLayout(v, params) } catch (_: Exception) {}
                                        }
                                    }
                                } else if (service == null) {
                                    Toast.makeText(this@AutoClickerOverlayService, "Enable Accessibility in Settings!", Toast.LENGTH_SHORT).show()
                                }
                            }
                            return true
                        }
                    }
                    return false
                }

                // During mapping mode, it drags
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        params.x = initialX + (event.rawX - initialTouchX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        try { windowManager?.updateViewLayout(view, params) } catch (_: Exception) {}
                        return true
                    }
                }
                return false
            }
        })
    }

    // ── Mapping Toolbar ──────────────────────

    private fun showMappingToolbar(density: Float) {
        mappingToolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding((12 * density).toInt(), (10 * density).toInt(), (12 * density).toInt(), (10 * density).toInt())
            gravity = Gravity.CENTER_VERTICAL

            val bg = GradientDrawable()
            bg.cornerRadius = 16 * density
            bg.setColor(Color.parseColor("#F0111215"))
            bg.setStroke((1.5 * density).toInt(), Color.parseColor("#4ADE80"))
            background = bg
        }

        // Point count label
        mappingCountLabel = TextView(this).apply {
            text = "${pointMarkers.size} pts"
            setTextColor(Color.parseColor("#4ADE80"))
            textSize = 11f
            setTypeface(null, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f
            )
        }
        mappingToolbar?.addView(mappingCountLabel)

        // Add point button
        val addBtn = createToolbarButton("+", "#4ADE80", "#0A0B0D", density) {
            if (pointMarkers.size < 10) {
                val screenW = resources.displayMetrics.widthPixels
                val screenH = resources.displayMetrics.heightPixels
                val markerSize = (48 * density).toInt()
                // Place new point at center of screen
                addMarkerAtPixel(screenW / 2, screenH / 2, markerSize, density)
                mappingCountLabel?.text = "${pointMarkers.size} pts"
            }
        }
        mappingToolbar?.addView(addBtn)

        // Remove last point button
        val removeBtn = createToolbarButton("−", "#EF4444", "#FFFFFF", density) {
            if (pointMarkers.size > 1) {
                val last = pointMarkers.removeAt(pointMarkers.size - 1)
                markerLayoutParams.removeAt(markerLayoutParams.size - 1)
                try { windowManager?.removeView(last) } catch (_: Exception) {}
                mappingCountLabel?.text = "${pointMarkers.size} pts"
            }
        }
        mappingToolbar?.addView(removeBtn)

        // Save button
        val saveBtn = createToolbarButton("✓ SAVE", "#4ADE80", "#0A0B0D", density) {
            saveMappingPositions()
        }
        mappingToolbar?.addView(saveBtn)

        // Cancel button
        val cancelBtn = createToolbarButton("✕", "#64748B", "#FFFFFF", density) {
            exitMappingMode()
            edgeButton?.visibility = View.VISIBLE
            triggerButton?.visibility = View.VISIBLE
        }
        mappingToolbar?.addView(cancelBtn)

        val screenWidth = resources.displayMetrics.widthPixels
        val margin = (20 * density).toInt()

        mappingToolbarParams = WindowManager.LayoutParams(
            screenWidth - margin * 2,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        mappingToolbarParams?.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        mappingToolbarParams?.y = (20 * density).toInt()

        try { windowManager?.addView(mappingToolbar, mappingToolbarParams) } catch (_: Exception) {}
    }

    private fun createToolbarButton(
        text: String, bgHex: String, textHex: String,
        density: Float, onClick: () -> Unit
    ): View {
        val btn = TextView(this).apply {
            this.text = text
            setTextColor(Color.parseColor(textHex))
            textSize = 11f
            setTypeface(null, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(
                (12 * density).toInt(), (8 * density).toInt(),
                (12 * density).toInt(), (8 * density).toInt()
            )
            setOnClickListener { onClick() }
        }
        val bg = GradientDrawable()
        bg.cornerRadius = 8 * density
        bg.setColor(Color.parseColor(bgHex))
        btn.background = bg
        btn.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { marginStart = (4 * density).toInt() }
        return btn
    }

    // ── Save & Exit Mapping ──────────────────

    private fun saveMappingPositions() {
        val density = resources.displayMetrics.density
        val markerSize = (48 * density).toInt()
        val halfSize = markerSize / 2

        // Convert marker positions to touch point coordinates
        touchPoints.clear()
        for (params in markerLayoutParams) {
            val centerX = (params.x + halfSize).toFloat()
            val centerY = (params.y + halfSize).toFloat()
            touchPoints.add(floatArrayOf(centerX, centerY))
        }
        pointCount = touchPoints.size

        // Update the running clicker service immediately
        val service = AutoClickerService.instance
        if (service != null && AutoClickerService.isRunning) {
            service.updateSettings(intervalMs.toLong(), touchPoints)
        }

        exitMappingMode()

        // Show edge button and refresh panel with new point count
        edgeButton?.visibility = View.VISIBLE
        refreshPanel()
    }

    private fun exitMappingMode() {
        if (!isMapping) return
        isMapping = false

        // Remove toolbar ONLY. Do NOT remove markers, they act as triggers!
        try { windowManager?.removeView(mappingToolbar) } catch (_: Exception) {}
        mappingToolbar = null
        mappingCountLabel = null
    }

    // ═══════════════════════════════════════════
    // LIFECYCLE
    // ═══════════════════════════════════════════

    override fun onDestroy() {
        super.onDestroy()
        AutoClickerService.instance?.stopClicking()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        exitMappingMode()
        try { windowManager?.removeView(edgeButton) } catch (_: Exception) {}
        try { windowManager?.removeView(triggerButton) } catch (_: Exception) {}
        try { windowManager?.removeView(panelLayout) } catch (_: Exception) {}
        for (marker in pointMarkers) {
            try { windowManager?.removeView(marker) } catch (_: Exception) {}
        }
        pointMarkers.clear()
        markerLayoutParams.clear()
        edgeButton = null; triggerButton = null; panelLayout = null; windowManager = null
        try { unregisterReceiver(stopReceiver) } catch (_: Exception) {}
    }
}
