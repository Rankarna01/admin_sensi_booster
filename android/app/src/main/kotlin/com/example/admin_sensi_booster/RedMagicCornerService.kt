package com.example.admin_sensi_booster

import android.animation.ValueAnimator
import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.CornerPathEffect
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.GridLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.io.RandomAccessFile

// ─── Custom View untuk Background Axeron Style ──────────────────────────────
class AxeronBgView(context: Context) : View(context) {
    private val path = Path()
    
    private val paintFill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#E60A0A0A") // Dark glass pekat
        style = Paint.Style.FILL
        pathEffect = CornerPathEffect(15f) // Membulatkan sudut tajam poligon
    }
    
    private val paintStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 5f
        pathEffect = CornerPathEffect(15f)
    }
    
    private val paintGlow = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 30f
        maskFilter = BlurMaskFilter(25f, BlurMaskFilter.Blur.OUTER)
        pathEffect = CornerPathEffect(15f)
    }

    var glowAlpha = 0.6f
        set(value) {
            field = value
            invalidate()
        }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val pad = 35f // Ruang untuk efek glow
        
        // Membuat gradien neon (Ungu -> Merah -> Oranye) sesuai gambar
        val gradient = LinearGradient(
            0f, 0f, w, 0f,
            intArrayOf(
                Color.parseColor("#9D00FF"), // Ungu kiri
                Color.parseColor("#FF0033"), // Merah tengah
                Color.parseColor("#FF5500")  // Oranye kanan
            ),
            null,
            Shader.TileMode.CLAMP
        )
        
        paintStroke.shader = gradient
        paintGlow.shader = gradient
        paintGlow.alpha = (255 * glowAlpha).toInt()

        // Menggambar bentuk geometris ala Gaming HUD (Poligon bersudut)
        path.reset()
        val angleOffset = w * 0.05f
        val wingWidth = w * 0.35f
        val topY = pad + h * 0.15f
        
        // Mulai dari kiri bawah
        path.moveTo(pad, h - pad)
        // Kiri atas (miring)
        path.lineTo(pad + angleOffset, topY)
        // Sayap kiri atas
        path.lineTo(wingWidth, topY)
        // Tanjakan ke tengah
        path.lineTo(wingWidth + angleOffset, pad)
        // Atap tengah
        path.lineTo(w - wingWidth - angleOffset, pad)
        // Turunan dari tengah
        path.lineTo(w - wingWidth, topY)
        // Sayap kanan atas
        path.lineTo(w - pad - angleOffset, topY)
        // Kanan bawah (miring)
        path.lineTo(w - pad, h - pad)
        path.close()

        canvas.drawPath(path, paintFill)
        canvas.drawPath(path, paintGlow)
        canvas.drawPath(path, paintStroke)
    }
}

// ─── Custom Vector Icons for Features ──────────────────────────────────
class VectorIconView(context: Context, private val type: String) : View(context) {
    private val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#DDDDDD")
        style = Paint.Style.STROKE
        strokeWidth = 3f
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }
    private val fillP = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#DDDDDD")
        style = Paint.Style.FILL
    }
    
    fun setColor(color: Int) {
        p.color = color
        fillP.color = color
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val cx = w / 2f
        val cy = h / 2f
        val r = Math.min(w, h) * 0.35f

        when (type) {
            "floating" -> {
                canvas.drawRect(cx - r, cy - r*0.2f, cx - r*0.4f, cy + r, p)
                canvas.drawRect(cx - r*0.2f, cy - r*0.6f, cx + r*0.2f, cy + r, p)
                canvas.drawRect(cx + r*0.4f, cy - r, cx + r, cy + r, p)
            }
            "crosshair" -> {
                canvas.drawCircle(cx, cy, r, p)
                canvas.drawLine(cx, cy - r*1.4f, cx, cy - r*0.5f, p)
                canvas.drawLine(cx, cy + r*1.4f, cx, cy + r*0.5f, p)
                canvas.drawLine(cx - r*1.4f, cy, cx - r*0.5f, cy, p)
                canvas.drawLine(cx + r*1.4f, cy, cx + r*0.5f, cy, p)
                canvas.drawCircle(cx, cy, r*0.2f, fillP)
            }
            "cpu" -> {
                canvas.drawRect(cx - r*0.7f, cy - r*0.7f, cx + r*0.7f, cy + r*0.7f, p)
                canvas.drawRect(cx - r*0.3f, cy - r*0.3f, cx + r*0.3f, cy + r*0.3f, p)
            }
            "gpu" -> {
                canvas.drawRect(cx - r*0.9f, cy - r*0.7f, cx + r*0.9f, cy + r*0.7f, p)
                canvas.drawLine(cx - r*0.4f, cy + r*0.7f, cx - r*0.6f, cy + r*1.2f, p)
                canvas.drawLine(cx + r*0.4f, cy + r*0.7f, cx + r*0.6f, cy + r*1.2f, p)
            }
            "ping" -> {
                canvas.drawArc(cx - r, cy - r, cx + r, cy + r, 225f, 90f, false, p)
                canvas.drawArc(cx - r*0.5f, cy - r*0.5f, cx + r*0.5f, cy + r*0.5f, 225f, 90f, false, p)
                canvas.drawCircle(cx, cy + r*0.3f, r*0.15f, fillP)
            }
            "click" -> {
                val path = Path()
                path.moveTo(cx - r*0.2f, cy - r*0.8f)
                path.lineTo(cx + r*0.6f, cy + r*0.6f)
                path.lineTo(cx + r*0.1f, cy + r*0.6f)
                path.lineTo(cx + r*0.1f, cy + r*1.2f)
                path.lineTo(cx - r*0.3f, cy + r*1.2f)
                path.lineTo(cx - r*0.3f, cy + r*0.6f)
                path.lineTo(cx - r*0.7f, cy + r*0.6f)
                path.close()
                canvas.drawPath(path, p)
            }
            "sensi" -> {
                canvas.drawCircle(cx - r*0.5f, cy, r*0.1f, fillP)
                canvas.drawCircle(cx + r*0.5f, cy, r*0.1f, fillP)
            }
            "dpi" -> {
                canvas.drawCircle(cx - r*0.2f, cy - r*0.2f, r*0.6f, p)
                canvas.drawLine(cx + r*0.2f, cy + r*0.2f, cx + r*0.9f, cy + r*0.9f, p)
            }
            else -> {
                canvas.drawCircle(cx, cy, r, p)
            }
        }
    }
}

// ─── Main Service ──────────────────────────────────────────────────────
class RedMagicCornerService : Service() {

    companion object {
        var isRunning = false
        const val ACTION_STOP = "com.example.admin_sensi_booster.STOP_REDMAGIC_CORNER"

        val FEATURES = listOf(
            Triple("floating_game",  "Refresh Rate", "floating"),
            Triple("crosshair",      "Crosshair",    "crosshair"),
            Triple("cpu_tweak",      "Monitor",      "cpu"),
            Triple("graphics_tweak", "Speed UP",     "gpu"),
            Triple("latency_mode",   "Ping Opt",     "ping"),
            Triple("auto_clicker",   "Aim",          "click"),
            Triple("game_lab_sensi", "Brightness",   "sensi"),
            Triple("set_dpi",        "DND",          "dpi"),
        )
    }

    private lateinit var wm: WindowManager
    private lateinit var logoView: LinearLayout
    private var panelContainer: FrameLayout? = null
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var statsRunnable: Runnable

    private var allowedFeatures: List<String> = emptyList()

    private var cpuPct    = 0.0
    private var ramUsedGB = 0.0
    private var ramTotGB  = 0.0
    private var panelVisible = false

    private var tvFps: TextView? = null

    private var slideAnimator: ValueAnimator? = null
    private var glowAnimator: ValueAnimator? = null

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, i: Intent) { if (i.action == ACTION_STOP) stopSelf() }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) { stopSelf(); return START_NOT_STICKY }

        val featureStr = intent?.getStringExtra("allowedFeatures") ?: ""
        // Fallback untuk testing: Jika kosong, gunakan semua fitur agar UI penuh
        allowedFeatures = if (featureStr.isBlank()) FEATURES.map { it.first } else featureStr.split(",")

        isRunning = true
        startForegroundNotification()
        registerReceiver(stopReceiver, IntentFilter(ACTION_STOP))

        setupLogo()
        startStatsLoop()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        handler.removeCallbacksAndMessages(null)
        slideAnimator?.cancel()
        glowAnimator?.cancel()
        removePanelSafe()
        try { wm.removeView(logoView) } catch (_: Exception) {}
        try { unregisterReceiver(stopReceiver) } catch (_: Exception) {}
    }

    private fun startForegroundNotification() {
        val chId = "redmagic_corner"
        val nm   = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(chId, "Axeron Corner", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val stopI = Intent(ACTION_STOP)
        val stopPi = android.app.PendingIntent.getBroadcast(
            this, 99, stopI, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        val n: Notification = NotificationCompat.Builder(this, chId)
            .setContentTitle("Axeron Game Corner Aktif")
            .setContentText("Overlay game sedang aktif")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .addAction(android.R.drawable.ic_delete, "Tutup", stopPi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        startForeground(1099, n)
    }

    private fun overlayType() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
    else
        WindowManager.LayoutParams.TYPE_PHONE

    private fun setupLogo() {
        wm = getSystemService(WINDOW_SERVICE) as WindowManager

        logoView = LinearLayout(this).apply { gravity = Gravity.CENTER }

        val bg = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor("#CC000000"))
            setStroke(5, Color.parseColor("#FF0033"))
        }

        val iv = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_compass)
            setColorFilter(Color.parseColor("#FFFFFF"))
            scaleType = ImageView.ScaleType.FIT_CENTER
            setPadding(14, 14, 14, 14)
        }

        logoView.background = bg
        logoView.addView(iv, LinearLayout.LayoutParams(120, 120))

        val lp = WindowManager.LayoutParams(
            130, 130,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP or Gravity.START; x = 20; y = 200 }

        wm.addView(logoView, lp)
        makeDraggableAndTappable(logoView, lp)
    }

    private fun makeDraggableAndTappable(view: View, lp: WindowManager.LayoutParams) {
        var ix = 0; var iy = 0; var tx = 0f; var ty = 0f

        view.setOnTouchListener { _, ev ->
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> { ix = lp.x; iy = lp.y; tx = ev.rawX; ty = ev.rawY; true }
                MotionEvent.ACTION_MOVE -> {
                    lp.x = ix + (ev.rawX - tx).toInt()
                    lp.y = iy + (ev.rawY - ty).toInt()
                    try { wm.updateViewLayout(view, lp) } catch (_: Exception) {}
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val dx = ev.rawX - tx; val dy = ev.rawY - ty
                    if (Math.abs(dx) < 12 && Math.abs(dy) < 12) {
                        if (panelVisible) removePanelSafe() else showPanel()
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun showPanel() {
        if (panelVisible) return
        panelVisible = true

        val root = FrameLayout(this)
        
        // 1. Tambahkan Custom Background (Axeron Polygon)
        val bgView = AxeronBgView(this)
        root.addView(bgView, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))

        // 2. Animasi Breathing Glow
        glowAnimator = ValueAnimator.ofFloat(0.4f, 0.8f).apply {
            duration = 1000
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
            addUpdateListener { anim -> bgView.glowAlpha = anim.animatedValue as Float }
            start()
        }

        // 3. Main Container Horizontal (Sayap Kiri - Tengah - Sayap Kanan)
        val mainRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(50, 40, 50, 60)
        }

        val visibleFeats = FEATURES.filter { it.first in allowedFeatures }
        val halfSize = if (visibleFeats.size > 4) 4 else visibleFeats.size / 2
        val leftFeats = visibleFeats.take(halfSize)
        val rightFeats = visibleFeats.drop(halfSize)

        // --- BAGIAN KIRI (Teks CPU Vertikal & Grid Kiri) ---
        val leftSection = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        
        val tvCpu = TextView(this).apply {
            text = "CPU\n${cpuPct.toInt()}%"
            textSize = 10f
            setTextColor(Color.parseColor("#9D00FF"))
            typeface = Typeface.DEFAULT_BOLD
            rotation = -90f // Putar teks vertikal
        }
        leftSection.addView(tvCpu)

        val leftGrid = GridLayout(this).apply {
            columnCount = 2
            rowCount = 2
            alignmentMode = GridLayout.ALIGN_BOUNDS
        }
        leftFeats.forEach { (_, label, emoji) -> leftGrid.addView(buildFeatureBtn(emoji, label)) }
        leftSection.addView(leftGrid)

        // --- BAGIAN TENGAH (Branding) ---
        val centerSection = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            setPadding(20, 0, 20, 0)
        }

        val badgeAxMode = TextView(this).apply {
            text = "AX-MODE"
            textSize = 12f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            setPadding(30, 8, 30, 8)
            background = GradientDrawable().apply {
                cornerRadius = 30f
                setColor(Color.parseColor("#FF0033"))
            }
        }
        
        tvFps = TextView(this).apply {
            text = "FPS: 60"
            textSize = 10f
            setTextColor(Color.parseColor("#CCCCCC"))
            setPadding(0, 8, 0, 8)
        }
        
        val titleAxeron = TextView(this).apply {
            text = "AXERON\nGAME CORNER"
            textSize = 14f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setShadowLayer(5f, 0f, 0f, Color.parseColor("#FF0033"))
        }

        centerSection.addView(badgeAxMode)
        centerSection.addView(tvFps)
        centerSection.addView(titleAxeron)
        
        // Klik pada logo tengah untuk menutup overlay
        centerSection.setOnClickListener { removePanelSafe() }

        // --- BAGIAN KANAN (Grid Kanan & Teks RAM Vertikal) ---
        val rightSection = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }

        val rightGrid = GridLayout(this).apply {
            columnCount = 2
            rowCount = 2
            alignmentMode = GridLayout.ALIGN_BOUNDS
        }
        rightFeats.forEach { (_, label, emoji) -> rightGrid.addView(buildFeatureBtn(emoji, label)) }
        rightSection.addView(rightGrid)
        
        val ramText = "${String.format("%.1f", ramUsedGB)}G"
        val tvRam = TextView(this).apply {
            text = "RAM\n$ramText"
            textSize = 10f
            setTextColor(Color.parseColor("#FF5500"))
            typeface = Typeface.DEFAULT_BOLD
            rotation = 90f // Putar teks vertikal
        }
        rightSection.addView(tvRam)

        // Gabungkan semua ke Main Row
        mainRow.addView(leftSection)
        mainRow.addView(centerSection)
        mainRow.addView(rightSection)

        root.addView(mainRow, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT).apply {
            gravity = Gravity.CENTER
        })

        // Setup LayoutParams untuk overlay lebar horizontal
        val screenWidth = resources.displayMetrics.widthPixels
        val lp = WindowManager.LayoutParams(
            (screenWidth * 0.95).toInt(), // Lebar 95% layar
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply { 
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = -500 // Start dari atas luar layar
        }

        try {
            wm.addView(root, lp)
            panelContainer = root

            // Slide down animation dari atas (Top Down)
            slideAnimator = ValueAnimator.ofInt(-500, 100).apply {
                duration = 400
                interpolator = DecelerateInterpolator()
                addUpdateListener { anim ->
                    lp.y = anim.animatedValue as Int
                    try { wm.updateViewLayout(root, lp) } catch (_: Exception) {}
                }
                start()
            }

        } catch (e: Exception) { panelVisible = false }
    }

    private fun buildFeatureBtn(iconType: String, label: String): View {
        val cell = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(4, 12, 4, 12)
        }
        
        val iconView = VectorIconView(this, iconType).apply {
            layoutParams = LinearLayout.LayoutParams(35, 35).apply {
                setMargins(0, 0, 0, 4)
            }
        }
        
        val lbl = TextView(this).apply {
            text = label
            textSize = 8f
            setTextColor(Color.parseColor("#BBBBBB"))
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
            maxLines = 1
        }
        
        cell.addView(iconView)
        cell.addView(lbl)

        cell.layoutParams = GridLayout.LayoutParams().apply {
            width = (resources.displayMetrics.density * 55).toInt()
            height = GridLayout.LayoutParams.WRAP_CONTENT
            setMargins(4, 4, 4, 4)
        }

        var on = false
        cell.setOnClickListener {
            on = !on
            iconView.setColor(if (on) Color.parseColor("#FF0033") else Color.parseColor("#DDDDDD"))
            lbl.setTextColor(if (on) Color.WHITE else Color.parseColor("#BBBBBB"))
        }
        return cell
    }

    private fun removePanelSafe() {
        slideAnimator?.cancel()
        glowAnimator?.cancel()
        panelVisible = false
        panelContainer?.let {
            try { wm.removeView(it) } catch (_: Exception) {}
        }
        panelContainer = null
        tvFps = null
    }

    private fun startStatsLoop() {
        statsRunnable = object : Runnable {
            override fun run() {
                fetchStats()
                // Update FPS Mockup & CPU Text saat panel terbuka
                if (panelVisible) {
                    val randomFps = (55..60).random()
                    tvFps?.text = "FPS: $randomFps"
                }
                handler.postDelayed(this, 2000)
            }
        }
        handler.post(statsRunnable)
    }

    private fun fetchStats() {
        try {
            val r1 = RandomAccessFile("/proc/stat", "r")
            val l1 = r1.readLine(); r1.close()
            val p1 = l1.trim().split("\\s+".toRegex()).drop(1).map { it.toLong() }
            val id1 = p1[3]; val tot1 = p1.sum()
            Thread.sleep(200)
            val r2 = RandomAccessFile("/proc/stat", "r")
            val l2 = r2.readLine(); r2.close()
            val p2 = l2.trim().split("\\s+".toRegex()).drop(1).map { it.toLong() }
            val id2 = p2[3]; val tot2 = p2.sum()
            val dI = id2 - id1; val dT = tot2 - tot1
            cpuPct = if (dT > 0) ((dT - dI).toDouble() / dT * 100) else 0.0
        } catch (_: Exception) { cpuPct = 0.0 }

        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mi = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mi)
        ramTotGB = mi.totalMem.toDouble() / (1024.0 * 1024.0 * 1024.0)
        ramUsedGB = (mi.totalMem - mi.availMem).toDouble() / (1024.0 * 1024.0 * 1024.0)
    }
}