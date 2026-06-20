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
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
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

// ─── Custom View for Red Magic Background ──────────────────────────────
class RedMagicBgView(context: Context) : View(context) {
    private val path = Path()
    private val paintFill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#E60A0000") // Very dark red, 90% opacity
        style = Paint.Style.FILL
    }
    private val paintStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#CCFF0000")
        style = Paint.Style.STROKE
        strokeWidth = 4f
    }
    private val paintGlow = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#66FF0000")
        style = Paint.Style.STROKE
        strokeWidth = 15f
        maskFilter = BlurMaskFilter(15f, BlurMaskFilter.Blur.NORMAL)
    }
    private val spikePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#FF0000")
        style = Paint.Style.FILL
    }

    var glowAlpha = 0.4f
        set(value) {
            field = value
            paintGlow.color = Color.argb((255 * value).toInt(), 255, 0, 0)
            invalidate()
        }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val r = 24f
        val wingTop = 0.16f

        path.reset()
        path.moveTo(w * 0.04f + r, h)
        path.quadTo(w * 0.04f, h, w * 0.04f, h - r)
        path.lineTo(w * 0.12f, h * wingTop)
        path.lineTo(w * 0.40f, h * wingTop)
        path.lineTo(w * 0.43f, 0f)
        path.lineTo(w * 0.57f, 0f)
        path.lineTo(w * 0.60f, h * wingTop)
        path.lineTo(w * 0.88f, h * wingTop)
        path.lineTo(w * 0.96f, h - r)
        path.quadTo(w * 0.96f, h, w * 0.96f - r, h)
        path.close()

        canvas.drawPath(path, paintFill)
        canvas.drawPath(path, paintGlow)
        canvas.drawPath(path, paintStroke)

        val spike = Path()
        spike.moveTo(w * 0.40f, h * wingTop)
        spike.lineTo(w * 0.43f, 0f)
        spike.lineTo(w * 0.57f, 0f)
        spike.lineTo(w * 0.60f, h * wingTop)
        spike.close()
        canvas.drawPath(spike, spikePaint)
    }
}

// ─── Main Service ──────────────────────────────────────────────────────
class RedMagicCornerService : Service() {

    companion object {
        var isRunning = false
        const val ACTION_STOP = "com.example.admin_sensi_booster.STOP_REDMAGIC_CORNER"

        val FEATURES = listOf(
            Triple("floating_game",  "Floating",  "📊"),
            Triple("crosshair",      "Crosshair", "🎯"),
            Triple("cpu_tweak",      "CPU",       "⚡"),
            Triple("graphics_tweak","GPU",        "🖥"),
            Triple("latency_mode",  "Low Ping",  "📡"),
            Triple("auto_clicker",  "AutoClick", "👆"),
            Triple("game_lab_sensi","Sensi",     "🎮"),
            Triple("set_dpi",       "DPI",       "🔍"),
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
    private var battPct   = 0
    private var tempC     = 0.0
    private var panelVisible = false

    private var tvCpu: TextView?  = null
    private var tvRam: TextView?  = null
    private var tvBat: TextView?  = null
    private var tvTemp: TextView? = null

    private var slideAnimator: ValueAnimator? = null
    private var glowAnimator: ValueAnimator? = null

    private val battReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            val lv = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, 0)
            val sc = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
            battPct = if (sc > 0) lv * 100 / sc else 0
            val tr  = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)
            tempC   = tr / 10.0
        }
    }

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, i: Intent) { if (i.action == ACTION_STOP) stopSelf() }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) { stopSelf(); return START_NOT_STICKY }

        val featureStr = intent?.getStringExtra("allowedFeatures") ?: ""
        allowedFeatures = if (featureStr.isBlank()) emptyList() else featureStr.split(",")

        isRunning = true
        startForegroundNotification()
        registerReceiver(battReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
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
        try { unregisterReceiver(battReceiver) } catch (_: Exception) {}
        try { unregisterReceiver(stopReceiver) } catch (_: Exception) {}
    }

    private fun startForegroundNotification() {
        val chId = "redmagic_corner"
        val nm   = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(chId, "Red Magic Corner", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val stopI = Intent(ACTION_STOP)
        val stopPi = android.app.PendingIntent.getBroadcast(
            this, 99, stopI, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        val n: Notification = NotificationCompat.Builder(this, chId)
            .setContentTitle("RedMagic Corner Aktif")
            .setContentText("Corner sedang aktif di atas game")
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
            setStroke(5, Color.parseColor("#CC2222"))
        }

        val iv = ImageView(this).apply {
            try {
                setImageResource(R.mipmap.ic_launcher)
            } catch (_: Exception) {
                setImageResource(android.R.drawable.ic_menu_compass)
                setColorFilter(Color.parseColor("#FF3333"))
            }
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
        
        // 1. Add Custom Background (Red Magic Wings)
        val bgView = RedMagicBgView(this)
        root.addView(bgView, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))

        // 2. Start Glow Breathing Animation
        glowAnimator = ValueAnimator.ofFloat(0.2f, 0.7f).apply {
            duration = 1200
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
            addUpdateListener { anim -> bgView.glowAlpha = anim.animatedValue as Float }
            start()
        }

        // 3. Add Content Layout
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = Gravity.CENTER_HORIZONTAL
            // Padding so content stays inside the wing shape
            setPadding(70, 45, 70, 30)
        }

        val header = TextView(this).apply {
            text      = "RED MAGIC"
            textSize  = 13f
            setTextColor(Color.parseColor("#FF2222"))
            typeface  = Typeface.DEFAULT_BOLD
            gravity   = Gravity.CENTER
            letterSpacing = 0.2f
        }
        content.addView(header, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(0, 0, 0, 20) })

        val statsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.CENTER
            setPadding(0, 8, 0, 16)
        }

        tvCpu  = buildStatChip("CPU",  "…%")
        tvRam  = buildStatChip("RAM",  "…")
        tvBat  = buildStatChip("BAT",  "…%")
        tvTemp = buildStatChip("TEMP", "…°")

        statsRow.addView(tvCpu!!.parent as View)
        statsRow.addView(tvRam!!.parent as View)
        statsRow.addView(tvBat!!.parent as View)
        statsRow.addView(tvTemp!!.parent as View)
        content.addView(statsRow)

        val visibleFeats = FEATURES.filter { it.first in allowedFeatures }
        if (visibleFeats.isNotEmpty()) {
            val div = View(this).apply { setBackgroundColor(Color.parseColor("#33FF0000")) }
            content.addView(div, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 2).apply { setMargins(20, 8, 20, 16) })

            val grid = GridLayout(this).apply {
                columnCount = 4
                rowCount    = Math.ceil(visibleFeats.size / 4.0).toInt()
            }
            visibleFeats.forEach { (_, label, emoji) ->
                grid.addView(buildFeatureBtn(emoji, label))
            }
            content.addView(grid, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 0, 0, 8) })
        }

        val closeBtn = TextView(this).apply {
            text     = "✕  Tutup"
            textSize = 10f
            setTextColor(Color.parseColor("#FF6666"))
            gravity  = Gravity.CENTER
            setPadding(32, 14, 32, 14)
            background = GradientDrawable().apply {
                cornerRadius = 24f
                setColor(Color.parseColor("#33FF0000"))
                setStroke(2, Color.parseColor("#66FF0000"))
            }
        }
        closeBtn.setOnClickListener { removePanelSafe() }
        content.addView(closeBtn, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { gravity = Gravity.CENTER_HORIZONTAL; setMargins(0, 16, 0, 10) })

        root.addView(content, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT))

        // Set LayoutParams & add to WindowManager
        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply { 
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = 300 // Start position offscreen or lower
        }

        try {
            wm.addView(root, lp)
            panelContainer = root

            // Slide up animation
            slideAnimator = ValueAnimator.ofInt(300, 60).apply {
                duration = 400
                interpolator = DecelerateInterpolator()
                addUpdateListener { anim ->
                    lp.y = anim.animatedValue as Int
                    try { wm.updateViewLayout(root, lp) } catch (_: Exception) {}
                }
                start()
            }

        } catch (e: Exception) { panelVisible = false }

        updateStatViews()
    }

    private fun buildStatChip(label: String, initialVal: String): TextView {
        val chip = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = Gravity.CENTER
            setPadding(20, 12, 20, 12)
            background = GradientDrawable().apply {
                cornerRadius = 14f
                setColor(Color.parseColor("#22FF0000"))
                setStroke(2, Color.parseColor("#55FF0000"))
            }
        }
        val lbl = TextView(this).apply {
            text      = label
            textSize  = 7f
            setTextColor(Color.parseColor("#AAFFFFFF"))
            gravity   = Gravity.CENTER
        }
        val tv = TextView(this).apply {
            text      = initialVal
            textSize  = 11f
            setTextColor(Color.WHITE)
            typeface  = Typeface.DEFAULT_BOLD
            gravity   = Gravity.CENTER
        }
        chip.addView(lbl)
        chip.addView(tv)
        chip.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(8, 0, 8, 0) }
        tv.tag = chip
        return tv
    }

    private fun buildFeatureBtn(emoji: String, label: String): View {
        val cell = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = Gravity.CENTER
            setPadding(24, 20, 24, 20)
        }
        val icon = TextView(this).apply {
            text     = emoji
            textSize = 22f
            gravity  = Gravity.CENTER
        }
        val lbl = TextView(this).apply {
            text      = label
            textSize  = 8f
            setTextColor(Color.parseColor("#DDFFFFFF"))
            gravity   = Gravity.CENTER
        }
        cell.addView(icon)
        cell.addView(lbl)

        cell.background = GradientDrawable().apply {
            cornerRadius = 18f
            setColor(Color.parseColor("#22FF0000"))
            setStroke(2, Color.parseColor("#55FF0000"))
        }

        cell.layoutParams = GridLayout.LayoutParams().apply {
            width  = GridLayout.LayoutParams.WRAP_CONTENT
            height = GridLayout.LayoutParams.WRAP_CONTENT
            setMargins(10, 10, 10, 10)
        }

        var on = false
        cell.setOnClickListener {
            on = !on
            cell.background = GradientDrawable().apply {
                cornerRadius = 18f
                setColor(if (on) Color.parseColor("#55FF0000") else Color.parseColor("#22FF0000"))
                setStroke(if (on) 3 else 2, if (on) Color.parseColor("#FFFF0000") else Color.parseColor("#55FF0000"))
            }
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
        tvCpu  = null; tvRam  = null
        tvBat  = null; tvTemp = null
    }

    private fun startStatsLoop() {
        statsRunnable = object : Runnable {
            override fun run() {
                fetchStats()
                updateStatViews()
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

    private fun updateStatViews() {
        if (!panelVisible) return
        tvCpu?.text  = "${cpuPct.toInt()}%"
        tvRam?.text  = "${String.format("%.1f", ramUsedGB)}/${String.format("%.0f", ramTotGB)}G"
        tvBat?.text  = "$battPct%"
        tvTemp?.text = "${String.format("%.0f", tempC)}°"
    }
}
