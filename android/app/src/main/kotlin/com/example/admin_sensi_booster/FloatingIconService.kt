package com.example.admin_sensi_booster

import android.app.Service
import android.content.Intent
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
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class FloatingIconService : Service() {
    private lateinit var windowManager: WindowManager
    private lateinit var rootLayout: LinearLayout
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var updateRunnable: Runnable

    private var tvRam: TextView? = null
    private var tvBattery: TextView? = null
    private var tvSuhu: TextView? = null
    private var tvClock: TextView? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val showRam = intent?.getBooleanExtra("showRam", true) ?: true
        val showBattery = intent?.getBooleanExtra("showBattery", true) ?: true
        val showSuhu = intent?.getBooleanExtra("showSuhu", true) ?: true
        val showClock = intent?.getBooleanExtra("showClock", true) ?: true

        if (::rootLayout.isInitialized) {
            windowManager.removeView(rootLayout)
            handler.removeCallbacks(updateRunnable)
        }
        setupView(showRam, showBattery, showSuhu, showClock)
        return START_NOT_STICKY
    }

    private fun setupView(showRam: Boolean, showBattery: Boolean, showSuhu: Boolean, showClock: Boolean) {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        // --- 1. ROOT LAYOUT (Bungkus Utama) ---
        rootLayout = LinearLayout(this)
        rootLayout.orientation = LinearLayout.HORIZONTAL
        rootLayout.gravity = Gravity.CENTER_VERTICAL

        // --- 2. SMART TOUCH BUTTON (Ikon Kotak di Kiri) ---
        val touchButton = ImageView(this)
        touchButton.setImageResource(android.R.drawable.ic_menu_add) // Icon sementara berbentuk +
        touchButton.setColorFilter(Color.WHITE)
        val btnDrawable = GradientDrawable()
        btnDrawable.shape = GradientDrawable.RECTANGLE
        btnDrawable.cornerRadius = 24f
        btnDrawable.setColor(Color.parseColor("#202020"))
        btnDrawable.setStroke(4, Color.parseColor("#39FF14")) // Border Neon Green
        touchButton.background = btnDrawable
        touchButton.setPadding(16, 16, 16, 16)
        
        val btnParams = LinearLayout.LayoutParams(90, 90)
        btnParams.setMargins(0, 0, 16, 0) // Margin agar tidak menempel dengan panel monitor
        touchButton.layoutParams = btnParams

        // --- 3. PERFORMANCE MONITOR PANEL (Kapsul Hitam di Kanan) ---
        val monitorPanel = LinearLayout(this)
        monitorPanel.orientation = LinearLayout.HORIZONTAL
        monitorPanel.gravity = Gravity.CENTER_VERTICAL
        monitorPanel.setPadding(24, 12, 24, 12)

        val bgDrawable = GradientDrawable()
        bgDrawable.shape = GradientDrawable.RECTANGLE
        bgDrawable.cornerRadius = 60f
        bgDrawable.setColor(Color.parseColor("#B3000000")) // Hitam pekat transparan
        monitorPanel.background = bgDrawable

        if (showRam) {
            tvRam = createTextView()
            monitorPanel.addView(tvRam)
        }
        if (showBattery) {
            tvBattery = createTextView()
            monitorPanel.addView(tvBattery)
        }
        if (showSuhu) {
            tvSuhu = createTextView()
            monitorPanel.addView(tvSuhu)
        }
        if (showClock) {
            tvClock = createTextView()
            monitorPanel.addView(tvClock)
        }

        // Tambahkan ke Root Layout
        rootLayout.addView(touchButton)
        rootLayout.addView(monitorPanel)

        // --- 4. WINDOW MANAGER PARAMS ---
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )

        layoutParams.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        layoutParams.y = 150

        windowManager.addView(rootLayout, layoutParams)

        // --- 5. LOGIK DRAG & KLIK ---
        rootLayout.setOnTouchListener(object : View.OnTouchListener {
            private var initialX: Int = 0
            private var initialY: Int = 0
            private var initialTouchX: Float = 0f
            private var initialTouchY: Float = 0f

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = layoutParams.x
                        initialY = layoutParams.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        layoutParams.x = initialX + (event.rawX - initialTouchX).toInt()
                        layoutParams.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager.updateViewLayout(rootLayout, layoutParams)
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        val diffX = event.rawX - initialTouchX
                        val diffY = event.rawY - initialTouchY
                        if (Math.abs(diffX) < 10 && Math.abs(diffY) < 10) {
                            // Tapped! Buka UI Smart Touch Dashboard
                            val intent = Intent(this@FloatingIconService, MainActivity::class.java)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            intent.putExtra("open_smart_touch", true)
                            startActivity(intent)
                        }
                        return true
                    }
                }
                return false
            }
        })

        startUpdating()
    }

    private fun createTextView(): TextView {
        val tv = TextView(this)
        tv.setTextColor(Color.WHITE)
        tv.textSize = 10f
        tv.setTypeface(null, android.graphics.Typeface.BOLD)
        val params = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        params.setMargins(15, 0, 15, 0)
        tv.layoutParams = params
        return tv
    }

    private fun startUpdating() {
        val sdf = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
        updateRunnable = object : Runnable {
            override fun run() {
                tvRam?.text = "RAM 56%" 
                tvBattery?.text = "BAT 72%" 
                tvSuhu?.text = "38°C" 
                tvClock?.text = sdf.format(Date())

                handler.postDelayed(this, 1000)
            }
        }
        handler.post(updateRunnable)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::rootLayout.isInitialized) {
            windowManager.removeView(rootLayout)
            handler.removeCallbacks(updateRunnable)
        }
    }
}
