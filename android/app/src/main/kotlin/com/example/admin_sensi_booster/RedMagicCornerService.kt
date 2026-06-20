package com.example.admin_sensi_booster

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
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
import android.widget.GridLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.io.RandomAccessFile

class RedMagicCornerService : Service() {

    companion object {
        var isRunning = false
        const val ACTION_STOP = "com.example.admin_sensi_booster.STOP_REDMAGIC_CORNER"

        // Feature definitions – key matches Firestore features map
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
    private var panelView: LinearLayout? = null
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var statsRunnable: Runnable

    // allowed feature keys passed from Flutter
    private var allowedFeatures: List<String> = emptyList()

    // live stats
    private var cpuPct    = 0.0
    private var ramUsedGB = 0.0
    private var ramTotGB  = 0.0
    private var battPct   = 0
    private var tempC     = 0.0
    private var panelVisible = false

    // UI refs inside panel
    private var tvCpu: TextView?  = null
    private var tvRam: TextView?  = null
    private var tvBat: TextView?  = null
    private var tvTemp: TextView? = null

    // ── battery receiver ─────────────────────────────────
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

    // ─────────────────────────────────────────────────────
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) { stopSelf(); return START_NOT_STICKY }

        // Read allowed features from Intent extras (comma-separated keys)
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
        removePanelSafe()
        try { wm.removeView(logoView) } catch (_: Exception) {}
        try { unregisterReceiver(battReceiver) } catch (_: Exception) {}
        try { unregisterReceiver(stopReceiver) } catch (_: Exception) {}
    }

    // ─── Foreground notification ──────────────────────────
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

    // ─── Overlay type helper ──────────────────────────────
    private fun overlayType() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
    else
        WindowManager.LayoutParams.TYPE_PHONE

    // ─── Logo floating icon ───────────────────────────────
    private fun setupLogo() {
        wm = getSystemService(WINDOW_SERVICE) as WindowManager

        logoView = LinearLayout(this).apply { gravity = Gravity.CENTER }

        // Circle background
        val bg = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor("#CC000000"))
            setStroke(5, Color.parseColor("#CC2222"))
        }

        // Logo image (ic_launcher as fallback)
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

    // ─── Drag + tap logic ─────────────────────────────────
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
                        // Tap → toggle panel
                        if (panelVisible) removePanelSafe() else showPanel()
                    }
                    true
                }
                else -> false
            }
        }
    }

    // ─── Panel build ──────────────────────────────────────
    private fun showPanel() {
        if (panelVisible) return
        panelVisible = true

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = Gravity.CENTER_HORIZONTAL
            setPadding(32, 24, 32, 24)
        }

        // Dark red rounded background
        val bg = GradientDrawable().apply {
            shape       = GradientDrawable.RECTANGLE
            cornerRadius = 32f
            setColor(Color.parseColor("#EE0A0000"))
            setStroke(3, Color.parseColor("#CC2222"))
        }
        root.background = bg

        // ── Header ──
        val header = TextView(this).apply {
            text      = "GAME CORNER"
            textSize  = 11f
            setTextColor(Color.parseColor("#FF4444"))
            typeface  = Typeface.DEFAULT_BOLD
            gravity   = Gravity.CENTER
            letterSpacing = 0.15f
        }
        root.addView(header, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(0, 0, 0, 18) })

        // ── Live stats row ──
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
        root.addView(statsRow)

        // ── Feature buttons grid ──
        val visibleFeats = FEATURES.filter { it.first in allowedFeatures }
        if (visibleFeats.isNotEmpty()) {
            val div = View(this).apply { setBackgroundColor(Color.parseColor("#33FF4444")) }
            root.addView(div, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 1).apply { setMargins(0, 4, 0, 16) })

            val grid = GridLayout(this).apply {
                columnCount = 4
                rowCount    = Math.ceil(visibleFeats.size / 4.0).toInt()
            }
            visibleFeats.forEach { (_, label, emoji) ->
                grid.addView(buildFeatureBtn(emoji, label))
            }
            root.addView(grid, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 0, 0, 8) })
        }

        // ── Close button ──
        val closeBtn = TextView(this).apply {
            text     = "✕  Tutup"
            textSize = 10f
            setTextColor(Color.parseColor("#FF6666"))
            gravity  = Gravity.CENTER
            setPadding(32, 14, 32, 14)
            val d = GradientDrawable().apply {
                cornerRadius = 24f
                setColor(Color.parseColor("#33FF0000"))
                setStroke(2, Color.parseColor("#66FF0000"))
            }
            background = d
        }
        closeBtn.setOnClickListener { removePanelSafe() }
        root.addView(closeBtn, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { gravity = Gravity.CENTER_HORIZONTAL; setMargins(0, 12, 0, 0) })

        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL; y = 60 }

        try {
            wm.addView(root, lp)
            panelView = root
        } catch (e: Exception) { panelVisible = false }

        updateStatViews()
    }

    private fun buildStatChip(label: String, initialVal: String): TextView {
        val chip = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = Gravity.CENTER
            setPadding(20, 10, 20, 10)
            val d = GradientDrawable().apply {
                cornerRadius = 14f
                setColor(Color.parseColor("#22FF3333"))
                setStroke(1, Color.parseColor("#44FF3333"))
            }
            background = d
        }
        val lbl = TextView(this).apply {
            text      = label
            textSize  = 7f
            setTextColor(Color.parseColor("#88FFFFFF"))
            gravity   = Gravity.CENTER
        }
        val tv = TextView(this).apply {
            text      = initialVal
            textSize  = 10f
            setTextColor(Color.WHITE)
            typeface  = Typeface.DEFAULT_BOLD
            gravity   = Gravity.CENTER
        }
        chip.addView(lbl)
        chip.addView(tv)
        chip.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(8, 0, 8, 0) }
        // Return the value TextView, but chip is added to parent
        // We'll tag the chip on the TextView so we can find it
        tv.tag = chip
        return tv
    }

    private fun buildFeatureBtn(emoji: String, label: String): View {
        val cell = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = Gravity.CENTER
            setPadding(20, 18, 20, 18)
        }
        val icon = TextView(this).apply {
            text     = emoji
            textSize = 20f
            gravity  = Gravity.CENTER
        }
        val lbl = TextView(this).apply {
            text      = label
            textSize  = 7f
            setTextColor(Color.parseColor("#CCFFFFFF"))
            gravity   = Gravity.CENTER
        }
        cell.addView(icon)
        cell.addView(lbl)

        val bg = GradientDrawable().apply {
            cornerRadius = 16f
            setColor(Color.parseColor("#22FF3333"))
            setStroke(1, Color.parseColor("#44CC0000"))
        }
        cell.background = bg

        val gp = GridLayout.LayoutParams().apply {
            width  = GridLayout.LayoutParams.WRAP_CONTENT
            height = GridLayout.LayoutParams.WRAP_CONTENT
            setMargins(8, 8, 8, 8)
        }
        cell.layoutParams = gp

        // Toggle highlight on tap
        var on = false
        cell.setOnClickListener {
            on = !on
            val newBg = GradientDrawable().apply {
                cornerRadius = 16f
                setColor(if (on) Color.parseColor("#44FF0000") else Color.parseColor("#22FF3333"))
                setStroke(if (on) 2 else 1, if (on) Color.parseColor("#CCFF0000") else Color.parseColor("#44CC0000"))
            }
            cell.background = newBg
        }
        return cell
    }

    private fun removePanelSafe() {
        panelVisible = false
        panelView?.let {
            try { wm.removeView(it) } catch (_: Exception) {}
        }
        panelView = null
        tvCpu  = null; tvRam  = null
        tvBat  = null; tvTemp = null
    }

    // ─── Stats loop ───────────────────────────────────────
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
        // CPU
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

        // RAM
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
