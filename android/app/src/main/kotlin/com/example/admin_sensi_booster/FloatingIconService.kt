package com.example.admin_sensi_booster

import android.app.ActivityManager
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
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Choreographer
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class FloatingIconService : Service(), Choreographer.FrameCallback {
    private lateinit var windowManager: WindowManager
    private lateinit var rootLayout: LinearLayout
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var updateRunnable: Runnable

    private var tvFps: TextView? = null
    private var tvRam: TextView? = null
    private var tvBattery: TextView? = null
    private var tvSuhu: TextView? = null
    private var tvClock: TextView? = null

    // Real data variables
    private var currentBatteryPct: Int = 0
    private var currentTempC: Int = 0
    private var fpsCounter = 0
    private var lastFpsTime: Long = 0
    private var currentFps = 60
    
    private val ACTION_STOP_SERVICE = "com.example.admin_sensi_booster.STOP_OVERLAY"

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            if (level != -1 && scale != -1) {
                currentBatteryPct = (level * 100) / scale
            }
            val temp = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
            if (temp > 0) {
                currentTempC = temp / 10 // Usually returned in tenths of a degree
            }
        }
    }

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_STOP_SERVICE) {
                stopSelf()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val showRam = intent?.getBooleanExtra("showRam", true) ?: true
        val showBattery = intent?.getBooleanExtra("showBattery", true) ?: true
        val showSuhu = intent?.getBooleanExtra("showSuhu", true) ?: true
        val showClock = intent?.getBooleanExtra("showClock", true) ?: true
        val showFps = intent?.getBooleanExtra("showFps", true) ?: true

        createNotificationAndStartForeground()

        if (::rootLayout.isInitialized) {
            try {
                windowManager.removeView(rootLayout)
            } catch (e: Exception) {}
            handler.removeCallbacks(updateRunnable)
            Choreographer.getInstance().removeFrameCallback(this)
            try { unregisterReceiver(batteryReceiver) } catch (e: Exception) {}
            try { unregisterReceiver(stopReceiver) } catch (e: Exception) {}
        }
        
        registerReceiver(batteryReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        registerReceiver(stopReceiver, IntentFilter(ACTION_STOP_SERVICE))
        
        setupView(showFps, showRam, showBattery, showSuhu, showClock)
        return START_NOT_STICKY
    }

    private fun createNotificationAndStartForeground() {
        val channelId = "floating_game_tools"
        val channelName = "Floating Game Tools"
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            notificationManager.createNotificationChannel(channel)
        }

        val stopIntent = Intent(ACTION_STOP_SERVICE)
        val pendingStopIntent = PendingIntent.getBroadcast(
            this, 0, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Floating Game Tools Aktif")
            .setContentText("Ketuk Nonaktifkan untuk menutup monitor.")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .addAction(android.R.drawable.ic_delete, "Nonaktifkan", pendingStopIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(1001, notification)
    }

    private fun setupView(showFps: Boolean, showRam: Boolean, showBattery: Boolean, showSuhu: Boolean, showClock: Boolean) {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        rootLayout = LinearLayout(this)
        rootLayout.orientation = LinearLayout.HORIZONTAL
        rootLayout.gravity = Gravity.CENTER_VERTICAL

        val touchButton = ImageView(this)
        touchButton.setImageResource(android.R.drawable.ic_menu_add)
        touchButton.setColorFilter(Color.WHITE)
        val btnDrawable = GradientDrawable()
        btnDrawable.shape = GradientDrawable.RECTANGLE
        btnDrawable.cornerRadius = 24f
        btnDrawable.setColor(Color.parseColor("#202020"))
        btnDrawable.setStroke(4, Color.parseColor("#39FF14"))
        touchButton.background = btnDrawable
        touchButton.setPadding(16, 16, 16, 16)
        
        val btnParams = LinearLayout.LayoutParams(90, 90)
        btnParams.setMargins(0, 0, 16, 0)
        touchButton.layoutParams = btnParams

        val monitorPanel = LinearLayout(this)
        monitorPanel.orientation = LinearLayout.HORIZONTAL
        monitorPanel.gravity = Gravity.CENTER_VERTICAL
        monitorPanel.setPadding(24, 12, 24, 12)

        val bgDrawable = GradientDrawable()
        bgDrawable.shape = GradientDrawable.RECTANGLE
        bgDrawable.cornerRadius = 60f
        bgDrawable.setColor(Color.parseColor("#B3000000"))
        monitorPanel.background = bgDrawable

        if (showFps) {
            tvFps = createTextView()
            monitorPanel.addView(tvFps)
        }
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

        rootLayout.addView(touchButton)
        rootLayout.addView(monitorPanel)

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

        try {
            windowManager.addView(rootLayout, layoutParams)
        } catch (e: Exception) {
            e.printStackTrace()
        }

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
                        try {
                            windowManager.updateViewLayout(rootLayout, layoutParams)
                        } catch (e: Exception) {}
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        val diffX = event.rawX - initialTouchX
                        val diffY = event.rawY - initialTouchY
                        if (Math.abs(diffX) < 10 && Math.abs(diffY) < 10) {
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

        lastFpsTime = System.currentTimeMillis()
        Choreographer.getInstance().postFrameCallback(this)
        
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

    override fun doFrame(frameTimeNanos: Long) {
        fpsCounter++
        val now = System.currentTimeMillis()
        if (now - lastFpsTime >= 1000) {
            currentFps = fpsCounter
            fpsCounter = 0
            lastFpsTime = now
        }
        Choreographer.getInstance().postFrameCallback(this)
    }

    private fun getRamUsage(): Int {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        val totalMemory = memoryInfo.totalMem
        val availableMemory = memoryInfo.availMem
        val usedMemory = totalMemory - availableMemory
        
        return ((usedMemory.toDouble() / totalMemory.toDouble()) * 100).toInt()
    }

    private fun startUpdating() {
        val sdf = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
        updateRunnable = object : Runnable {
            override fun run() {
                tvFps?.text = "FPS $currentFps"
                tvRam?.text = "RAM ${getRamUsage()}%"
                tvBattery?.text = "BAT $currentBatteryPct%"
                tvSuhu?.text = "$currentTempC°C"
                tvClock?.text = sdf.format(Date())

                handler.postDelayed(this, 1000)
            }
        }
        handler.post(updateRunnable)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::rootLayout.isInitialized) {
            try {
                windowManager.removeView(rootLayout)
            } catch (e: Exception) {}
            handler.removeCallbacks(updateRunnable)
            Choreographer.getInstance().removeFrameCallback(this)
            try { unregisterReceiver(batteryReceiver) } catch (e: Exception) {}
            try { unregisterReceiver(stopReceiver) } catch (e: Exception) {}
        }
    }
}
