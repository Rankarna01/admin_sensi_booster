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
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.TextView
import android.widget.ScrollView
import android.widget.HorizontalScrollView
import androidx.core.app.NotificationCompat

class CrosshairOverlayService : Service() {

    companion object {
        var isRunning: Boolean = false
            private set
    }

    private var windowManager: WindowManager? = null
    private var crosshairView: CrosshairView? = null
    private var settingsButtonView: FrameLayout? = null
    private var settingsPanelView: LinearLayout? = null

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
        val prefs = getSharedPreferences("CrosshairPrefs", Context.MODE_PRIVATE)
        val shape = intent?.getStringExtra("shape") ?: prefs.getString("shape", crosshairShape) ?: crosshairShape
        val color = intent?.getStringExtra("color") ?: prefs.getString("color", crosshairColor) ?: crosshairColor
        val size = intent?.getIntExtra("size", -1).takeIf { it != -1 } ?: prefs.getInt("size", crosshairSize)
        val opacity = intent?.getIntExtra("opacity", -1).takeIf { it != -1 } ?: prefs.getInt("opacity", crosshairOpacity)
        val offX = intent?.getIntExtra("offsetX", -9999).takeIf { it != -9999 } ?: prefs.getInt("offsetX", offsetX)
        val offY = intent?.getIntExtra("offsetY", -9999).takeIf { it != -9999 } ?: prefs.getInt("offsetY", offsetY)

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
        isRunning = true
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
            .setContentText("Double-tap crosshair to toggle off")
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
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.RGBA_8888
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            params.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        params.gravity = Gravity.TOP or Gravity.START

        try {
            windowManager?.addView(crosshairView, params)
            setupSettingsButton()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun saveSettings() {
        val prefs = getSharedPreferences("CrosshairPrefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("shape", crosshairShape)
            .putString("color", crosshairColor)
            .putInt("size", crosshairSize)
            .putInt("opacity", crosshairOpacity)
            .putInt("offsetX", offsetX)
            .putInt("offsetY", offsetY)
            .apply()
    }

    private fun setupSettingsButton() {
        val btnView = FrameLayout(this)
        val icon = ImageView(this).apply {
            try {
                val inputStream = assets.open("flutter_assets/assets/images/logo.png")
                val bitmap = BitmapFactory.decodeStream(inputStream)
                setImageBitmap(bitmap)
            } catch (e: Exception) {
                setImageResource(android.R.drawable.ic_menu_manage)
                setColorFilter(Color.parseColor("#00E676"))
            }
            setPadding(10, 10, 10, 10)
        }
        val bg = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor("#E6000000"))
            setStroke(4, Color.parseColor("#00E676"))
        }
        btnView.background = bg
        btnView.addView(icon, FrameLayout.LayoutParams(120, 120))

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 100
            y = 300
        }

        makeDraggable(btnView, params) {
            showSettingsPanel()
        }

        try {
            windowManager?.addView(btnView, params)
            settingsButtonView = btnView
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun makeDraggable(view: View, params: WindowManager.LayoutParams, onClick: () -> Unit) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var touchStartTime = 0L
        var isMoved = false

        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    touchStartTime = System.currentTimeMillis()
                    isMoved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(dx) > 15 || Math.abs(dy) > 15) {
                        isMoved = true
                        params.x = initialX + dx
                        params.y = initialY + dy
                        try { windowManager?.updateViewLayout(view, params) } catch (e: Exception) {}
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val touchDuration = System.currentTimeMillis() - touchStartTime
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (touchDuration < 200 || (!isMoved && Math.abs(dx) < 20 && Math.abs(dy) < 20)) {
                        onClick()
                    }
                    true
                }
                else -> false
            }
        }
    }

    inner class ShapeIconView(context: Context, val shapeName: String) : View(context) {
        var isSelectedShape = false
            set(value) { field = value; invalidate() }

        private val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 3f
            strokeCap = Paint.Cap.ROUND
        }
        private val fillP = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }
        
        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val w = width.toFloat()
            val h = height.toFloat()
            
            val bgRect = android.graphics.RectF(4f, 4f, w - 4f, h - 4f)
            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (isSelectedShape) Color.parseColor("#3300E676") else Color.TRANSPARENT
                style = Paint.Style.FILL
            }
            canvas.drawRoundRect(bgRect, 20f, 20f, bgPaint)
            
            val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (isSelectedShape) Color.parseColor("#00E676") else Color.parseColor("#444444")
                style = Paint.Style.STROKE
                strokeWidth = if (isSelectedShape) 4f else 2f
            }
            canvas.drawRoundRect(bgRect, 20f, 20f, borderPaint)

            p.color = if (isSelectedShape) Color.parseColor("#00E676") else Color.WHITE
            fillP.color = p.color

            val cx = w / 2f
            val cy = h / 2f
            val s = Math.min(w, h) * 0.35f
            
            when (shapeName) {
                "dot" -> canvas.drawCircle(cx, cy, s * 0.15f, fillP)
                "cross" -> drawCrossIcon(canvas, cx, cy, s)
                "cross_dot" -> { drawCrossIcon(canvas, cx, cy, s); canvas.drawCircle(cx, cy, s*0.25f, fillP) }
                "circle" -> { 
                    p.style = Paint.Style.STROKE; canvas.drawCircle(cx, cy, s*0.4f, p)
                    fillP.style = Paint.Style.FILL; canvas.drawCircle(cx, cy, s*0.06f, fillP) 
                }
                "t_shape" -> {
                    val half = s * 0.5f
                    canvas.drawLine(cx - half, cy - half * 0.3f, cx + half, cy - half * 0.3f, p)
                    canvas.drawLine(cx, cy - half * 0.3f, cx, cy + half, p)
                    canvas.drawCircle(cx, cy + half * 0.1f, s * 0.06f, fillP)
                }
                "diamond" -> {
                    val half = s * 0.35f
                    val path = Path()
                    path.moveTo(cx, cy - half)
                    path.lineTo(cx + half, cy)
                    path.lineTo(cx, cy + half)
                    path.lineTo(cx - half, cy)
                    path.close()
                    p.style = Paint.Style.STROKE; canvas.drawPath(path, p)
                    canvas.drawCircle(cx, cy, s*0.06f, fillP)
                }
                "plus_circle" -> {
                    val r = s * 0.35f
                    p.style = Paint.Style.STROKE; canvas.drawCircle(cx, cy, r, p)
                    val inner = r * 0.5f
                    canvas.drawLine(cx - inner, cy, cx + inner, cy, p)
                    canvas.drawLine(cx, cy - inner, cx, cy + inner, p)
                    canvas.drawCircle(cx, cy, s*0.05f, fillP)
                }
                "scope" -> {
                    val r = s * 0.45f
                    val gap = s * 0.15f
                    p.style = Paint.Style.STROKE; canvas.drawCircle(cx, cy, r, p)
                    canvas.drawLine(cx, cy - r, cx, cy - r + gap, p)
                    canvas.drawLine(cx, cy + r, cx, cy + r - gap, p)
                    canvas.drawLine(cx - r, cy, cx - r + gap, cy, p)
                    canvas.drawLine(cx + r, cy, cx + r - gap, cy, p)
                    canvas.drawCircle(cx, cy, s*0.05f, fillP)
                }
            }
        }
        
        private fun drawCrossIcon(canvas: Canvas, cx: Float, cy: Float, size: Float) {
            val half = size * 0.5f
            val gap = size * 0.12f
            canvas.drawLine(cx - half, cy, cx - gap, cy, p)
            canvas.drawLine(cx + gap, cy, cx + half, cy, p)
            canvas.drawLine(cx, cy - half, cx, cy - gap, p)
            canvas.drawLine(cx, cy + gap, cx, cy + half, p)
        }
    }

    inner class ColorIconView(context: Context, val colorHex: String) : View(context) {
        var isSelectedColor = false
            set(value) { field = value; invalidate() }
            
        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val w = width.toFloat()
            val h = height.toFloat()
            val bgRect = android.graphics.RectF(2f, 2f, w - 2f, h - 2f)
            
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = try { Color.parseColor(colorHex) } catch(e: Exception) { Color.WHITE }
                style = Paint.Style.FILL
            }
            canvas.drawRoundRect(bgRect, 20f, 20f, paint)
            
            if (isSelectedColor) {
                val strokeP = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    style = Paint.Style.STROKE
                    strokeWidth = 6f
                }
                canvas.drawRoundRect(bgRect, 20f, 20f, strokeP)
                
                val dotP = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    style = Paint.Style.FILL
                    setShadowLayer(4f, 0f, 0f, Color.BLACK)
                }
                canvas.drawCircle(w * 0.8f, h * 0.2f, 8f, dotP)
            }
        }
    }

    private fun showSettingsPanel() {
        if (settingsPanelView != null) return

        val context = this
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val density = resources.displayMetrics.density
        val panelWidth = (320 * density).toInt()

        val params = WindowManager.LayoutParams(
            panelWidth,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        val panel = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#1C1E22"))
                cornerRadius = 40f
                setStroke(2, Color.parseColor("#333333"))
            }
            setPadding(40, 40, 40, 40)
        }
        
        // Header
        val header = FrameLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = 30 }
        }
        
        val tabs = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            val colorTab = TextView(context).apply {
                text = "COLOR"
                setTextColor(Color.WHITE)
                textSize = 10f
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                setPadding(35, 15, 35, 15)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#00E676"))
                    cornerRadius = 20f
                }
            }
            val posTab = TextView(context).apply {
                text = "POSITION"
                setTextColor(Color.parseColor("#888888"))
                textSize = 10f
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                setPadding(35, 15, 35, 15)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#2A2D32"))
                    cornerRadius = 20f
                }
            }
            addView(colorTab)
            addView(View(context).apply { layoutParams = LinearLayout.LayoutParams(15, 1) })
            addView(posTab)
        }
        
        val closeIcon = TextView(context).apply {
            text = "✖"
            setTextColor(Color.WHITE)
            textSize = 18f
            gravity = Gravity.CENTER
            setOnClickListener {
                try { windowManager?.removeView(panel) } catch (e: Exception) {}
                settingsPanelView = null
            }
        }
        
        header.addView(tabs, FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT).apply { gravity = Gravity.START or Gravity.CENTER_VERTICAL })
        header.addView(closeIcon, FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT).apply { gravity = Gravity.END or Gravity.CENTER_VERTICAL })
        panel.addView(header)

        val scrollView = ScrollView(context)
        val contentLayout = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }

        // SHAPES
        val shapes = listOf("dot", "cross", "cross_dot", "circle", "t_shape", "diamond", "plus_circle", "scope")
        val shapeRow = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
        val hScrollShapes = HorizontalScrollView(context).apply {
            isHorizontalScrollBarEnabled = false
            addView(shapeRow)
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = 30 }
        }
        
        val shapeViews = mutableListOf<ShapeIconView>()
        for (sh in shapes) {
            val sView = ShapeIconView(context, sh).apply {
                isSelectedShape = (crosshairShape == sh)
                val sz = (55 * density).toInt()
                layoutParams = LinearLayout.LayoutParams(sz, sz).apply { setMargins(0, 0, 15, 0) }
                setOnClickListener {
                    crosshairShape = sh
                    shapeViews.forEach { it.isSelectedShape = false }
                    this.isSelectedShape = true
                    crosshairView?.updateSettings()
                }
            }
            shapeViews.add(sView)
            shapeRow.addView(sView)
        }
        contentLayout.addView(hScrollShapes)

        // COLOR
        val colorTitle = TextView(context).apply {
            text = "COLOR"
            setTextColor(Color.WHITE)
            textSize = 11f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, 15)
        }
        contentLayout.addView(colorTitle)
        
        val colors = listOf("#FF3B30", "#34C759", "#00E676", "#FFCC00", "#FFFFFF", "#FF3366", "#3399FF", "#000000")
        val colorRow = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
        val hScrollColors = HorizontalScrollView(context).apply {
            isHorizontalScrollBarEnabled = false
            addView(colorRow)
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = 30 }
        }
        
        val colorViews = mutableListOf<ColorIconView>()
        for (c in colors) {
            val cView = ColorIconView(context, c).apply {
                isSelectedColor = (crosshairColor.equals(c, ignoreCase = true))
                val w = (65 * density).toInt()
                val h = (50 * density).toInt()
                layoutParams = LinearLayout.LayoutParams(w, h).apply { setMargins(0, 0, 15, 0) }
                setOnClickListener {
                    crosshairColor = c
                    colorViews.forEach { it.isSelectedColor = false }
                    this.isSelectedColor = true
                    crosshairView?.updateSettings()
                }
            }
            colorViews.add(cView)
            colorRow.addView(cView)
        }
        contentLayout.addView(hScrollColors)

        // SIZE
        val sizeTitle = TextView(context).apply {
            text = "SIZE"
            setTextColor(Color.WHITE)
            textSize = 11f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, 10)
        }
        contentLayout.addView(sizeTitle)
        
        val sizeSeek = SeekBar(context).apply {
            max = 150
            progress = crosshairSize
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                progressDrawable.colorFilter = android.graphics.BlendModeColorFilter(Color.parseColor("#00E676"), android.graphics.BlendMode.SRC_IN)
                thumb.colorFilter = android.graphics.BlendModeColorFilter(Color.parseColor("#00E676"), android.graphics.BlendMode.SRC_IN)
            } else {
                progressDrawable.setColorFilter(Color.parseColor("#00E676"), android.graphics.PorterDuff.Mode.SRC_IN)
                thumb.setColorFilter(Color.parseColor("#00E676"), android.graphics.PorterDuff.Mode.SRC_IN)
            }
            setPadding(0, 0, 0, 30)
            setOnSeekBarChangeListener(object: SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    crosshairSize = progress.coerceAtLeast(5)
                    crosshairView?.updateSettings()
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })
        }
        contentLayout.addView(sizeSeek)
        
        // OPACITY
        val opTitle = TextView(context).apply {
            text = "OPACITY"
            setTextColor(Color.WHITE)
            textSize = 11f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, 10)
        }
        contentLayout.addView(opTitle)

        val opSeek = SeekBar(context).apply {
            max = 255
            progress = crosshairOpacity
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                progressDrawable.colorFilter = android.graphics.BlendModeColorFilter(Color.parseColor("#00E676"), android.graphics.BlendMode.SRC_IN)
                thumb.colorFilter = android.graphics.BlendModeColorFilter(Color.parseColor("#00E676"), android.graphics.BlendMode.SRC_IN)
            } else {
                progressDrawable.setColorFilter(Color.parseColor("#00E676"), android.graphics.PorterDuff.Mode.SRC_IN)
                thumb.setColorFilter(Color.parseColor("#00E676"), android.graphics.PorterDuff.Mode.SRC_IN)
            }
            setPadding(0, 0, 0, 30)
            setOnSeekBarChangeListener(object: SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    crosshairOpacity = progress.coerceAtLeast(10)
                    crosshairView?.updateSettings()
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })
        }
        contentLayout.addView(opSeek)
        
        // POSITION X
        val offsetXTitle = TextView(context).apply {
            text = "OFFSET X"
            setTextColor(Color.WHITE)
            textSize = 11f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, 10)
        }
        contentLayout.addView(offsetXTitle)

        val offsetXSeek = SeekBar(context).apply {
            max = 1000
            progress = offsetX + 500
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                progressDrawable.colorFilter = android.graphics.BlendModeColorFilter(Color.parseColor("#00E676"), android.graphics.BlendMode.SRC_IN)
                thumb.colorFilter = android.graphics.BlendModeColorFilter(Color.parseColor("#00E676"), android.graphics.BlendMode.SRC_IN)
            } else {
                progressDrawable.setColorFilter(Color.parseColor("#00E676"), android.graphics.PorterDuff.Mode.SRC_IN)
                thumb.setColorFilter(Color.parseColor("#00E676"), android.graphics.PorterDuff.Mode.SRC_IN)
            }
            setPadding(0, 0, 0, 30)
            setOnSeekBarChangeListener(object: SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    offsetX = progress - 500
                    crosshairView?.updateSettings()
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })
        }
        contentLayout.addView(offsetXSeek)
        
        // POSITION Y
        val offsetYTitle = TextView(context).apply {
            text = "OFFSET Y"
            setTextColor(Color.WHITE)
            textSize = 11f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, 10)
        }
        contentLayout.addView(offsetYTitle)

        val offsetYSeek = SeekBar(context).apply {
            max = 1000
            progress = offsetY + 500
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                progressDrawable.colorFilter = android.graphics.BlendModeColorFilter(Color.parseColor("#00E676"), android.graphics.BlendMode.SRC_IN)
                thumb.colorFilter = android.graphics.BlendModeColorFilter(Color.parseColor("#00E676"), android.graphics.BlendMode.SRC_IN)
            } else {
                progressDrawable.setColorFilter(Color.parseColor("#00E676"), android.graphics.PorterDuff.Mode.SRC_IN)
                thumb.setColorFilter(Color.parseColor("#00E676"), android.graphics.PorterDuff.Mode.SRC_IN)
            }
            setPadding(0, 0, 0, 30)
            setOnSeekBarChangeListener(object: SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    offsetY = progress - 500
                    crosshairView?.updateSettings()
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })
        }
        contentLayout.addView(offsetYSeek)

        // Reset Button
        val resetBtn = TextView(context).apply {
            text = "Reset Size & Position"
            setTextColor(Color.WHITE)
            textSize = 12f
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#2A2D32"))
                cornerRadius = 30f
            }
            setPadding(0, 25, 0, 25)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = 10 }
            
            setOnClickListener {
                crosshairSize = 40
                sizeSeek.progress = 40
                crosshairOpacity = 255
                opSeek.progress = 255
                offsetX = 0
                offsetXSeek.progress = 500
                offsetY = 0
                offsetYSeek.progress = 500
                crosshairView?.updateSettings()
            }
        }
        contentLayout.addView(resetBtn)

        scrollView.addView(contentLayout)
        panel.addView(scrollView)

        try {
            windowManager?.addView(panel, params)
            settingsPanelView = panel
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }



    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        try {
            crosshairView?.let { windowManager?.removeView(it) }
        } catch (e: Exception) {}
        try {
            settingsButtonView?.let { windowManager?.removeView(it) }
        } catch (e: Exception) {}
        try {
            settingsPanelView?.let { windowManager?.removeView(it) }
        } catch (e: Exception) {}
        crosshairView = null
        settingsButtonView = null
        settingsPanelView = null
        windowManager = null
        try { unregisterReceiver(stopReceiver) } catch (e: Exception) {}
    }

    // ====================================================================
    // LIGHTWEIGHT CROSSHAIR VIEW
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
        private var cachedSize: Float = 0f
        private var cachedStrokeWidth: Float = 2f
        private var cachedShape: String = "cross_dot"

        init {
            setLayerType(LAYER_TYPE_HARDWARE, null)
            updateSettings()
        }

        fun updateSettings() {
            cachedColor = try { Color.parseColor(crosshairColor) } catch (e: Exception) { Color.RED }
            cachedAlpha = crosshairOpacity
            cachedOutlineAlpha = (crosshairOpacity * 0.4).toInt()
            cachedShape = crosshairShape

            val density = resources.displayMetrics.density
            cachedSize = crosshairSize * density
            cachedStrokeWidth = (cachedSize * 0.08f).coerceAtLeast(2f)

            saveSettings()
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

            val density = resources.displayMetrics.density
            val cx = (width / 2f) + (offsetX * density)
            val cy = (height / 2f) + (offsetY * density)
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
