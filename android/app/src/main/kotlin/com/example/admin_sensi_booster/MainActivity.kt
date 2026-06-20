package com.example.admin_sensi_booster

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.VpnService
import android.net.Uri
import android.os.BatteryManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ComponentName
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import java.io.RandomAccessFile

class MainActivity : FlutterActivity() {
    private val VPN_CHANNEL = "com.mfw.sensi_booster/vpn"
    private val OVERLAY_CHANNEL = "com.mfw.sensi_booster/overlay"
    private val CROSSHAIR_CHANNEL = "com.mfw.sensi_booster/crosshair"
    private val AUTOCLICKER_CHANNEL = "com.mfw.sensi_booster/autoclicker"
    private val GAME_CHANNEL = "com.mfw.sensi_booster/game"
    private val REDMAGIC_CORNER_CHANNEL = "com.mfw.sensi_booster/redmagic_corner"
    private val VPN_REQUEST_CODE = 0x0F
    private val OVERLAY_REQUEST_CODE = 0x10
    private var pendingMode = "Normal"
    private var overlayChannel: MethodChannel? = null
    private val SHIZUKU_CHANNEL = "com.mfw.sensi_booster/shizuku"
    private val MACRO_SHIZUKU_CHANNEL = "com.mfw.sensi_booster/macro_shizuku"

    private var macroService: IShizukuMacroService? = null
    
    private val userServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            macroService = IShizukuMacroService.Stub.asInterface(service)
            Log.d("SensiBooster", "Shizuku UserService connected")
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            macroService = null
            Log.d("SensiBooster", "Shizuku UserService disconnected")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Macro Shizuku Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MACRO_SHIZUKU_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bindService" -> {
                    if (rikka.shizuku.Shizuku.pingBinder() && rikka.shizuku.Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
                        try {
                            val args = rikka.shizuku.Shizuku.UserServiceArgs(ComponentName(packageName, ShizukuMacroService::class.java.name))
                                .daemon(false)
                                .processNameSuffix("macro_service")
                                .debuggable(true)
                                .version(1)
                            rikka.shizuku.Shizuku.bindUserService(args, userServiceConnection)
                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "startMacro" -> {
                    val x = call.argument<Int>("x") ?: 0
                    val y = call.argument<Int>("y") ?: 0
                    val delayMs = call.argument<Int>("delayMs") ?: 100
                    
                    if (macroService != null) {
                        try {
                            macroService?.startAutoClick(x, y, delayMs)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "stopMacro" -> {
                    if (macroService != null) {
                        try {
                            macroService?.stopAutoClick()
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Shizuku Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHIZUKU_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkShizukuStatus" -> {
                    if (rikka.shizuku.Shizuku.pingBinder()) {
                        if (rikka.shizuku.Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
                            result.success("running_granted")
                        } else {
                            result.success("running_not_granted")
                        }
                    } else {
                        result.success("not_running")
                    }
                }
                "checkPermission" -> {
                    if (rikka.shizuku.Shizuku.pingBinder()) {
                        result.success(rikka.shizuku.Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED)
                    } else {
                        result.success(false)
                    }
                }
                "requestPermission" -> {
                    if (rikka.shizuku.Shizuku.pingBinder()) {
                        if (rikka.shizuku.Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                        } else {
                            rikka.shizuku.Shizuku.requestPermission(100)
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "runCommand" -> {
                    val cmd = call.argument<String>("command")
                    if (cmd != null && rikka.shizuku.Shizuku.pingBinder() && rikka.shizuku.Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
                        try {
                            val process = rikka.shizuku.Shizuku.newProcess(arrayOf("sh", "-c", cmd), null, null)
                            process.waitFor()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SHIZUKU_ERR", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // VPN Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val mode = call.argument<String>("mode") ?: "Normal"
                    pendingMode = mode
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        startVpnService(mode)
                    }
                    result.success(true)
                }
                "stopVpn" -> {
                    val intent = Intent(this, LocalVpnService::class.java)
                    intent.action = "STOP"
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Overlay Channel
        overlayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
        overlayChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkSmartTouchIntent" -> {
                    val opened = intent.getBooleanExtra("open_smart_touch", false)
                    intent.removeExtra("open_smart_touch")
                    result.success(opened)
                }
                "checkPermission" -> {
                    val hasPerm = Settings.canDrawOverlays(this)
                    result.success(hasPerm)
                }
                "requestPermission" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:\$packageName"))
                        startActivityForResult(intent, OVERLAY_REQUEST_CODE)
                        result.success(false)
                    } else {
                        result.success(true)
                    }
                }
                "startOverlay" -> {
                    if (Settings.canDrawOverlays(this)) {
                        val intent = Intent(this, FloatingIconService::class.java)
                        intent.putExtra("showRam", call.argument<Boolean>("showRam") ?: true)
                        intent.putExtra("showBattery", call.argument<Boolean>("showBattery") ?: true)
                        intent.putExtra("showSuhu", call.argument<Boolean>("showSuhu") ?: true)
                        intent.putExtra("showClock", call.argument<Boolean>("showClock") ?: true)
                        intent.putExtra("showFps", call.argument<Boolean>("showFps") ?: true)
                        startService(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopOverlay" -> {
                    stopService(Intent(this, FloatingIconService::class.java))
                    result.success(true)
                }
                "getDeviceStats" -> {
                    try {
                        // CPU usage from /proc/stat
                        var cpuPercent = 0.0
                        try {
                            val stat1 = RandomAccessFile("/proc/stat", "r")
                            val line1 = stat1.readLine(); stat1.close()
                            val parts1 = line1.trim().split("\\s+".toRegex()).drop(1).map { it.toLong() }
                            val idle1   = parts1[3]
                            val total1  = parts1.sum()
                            Thread.sleep(200)
                            val stat2 = RandomAccessFile("/proc/stat", "r")
                            val line2 = stat2.readLine(); stat2.close()
                            val parts2 = line2.trim().split("\\s+".toRegex()).drop(1).map { it.toLong() }
                            val idle2   = parts2[3]
                            val total2  = parts2.sum()
                            val dIdle   = idle2  - idle1
                            val dTotal  = total2 - total1
                            cpuPercent  = if (dTotal > 0) ((dTotal - dIdle).toDouble() / dTotal * 100) else 0.0
                        } catch (_: Exception) {}

                        // RAM
                        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val mi = ActivityManager.MemoryInfo()
                        am.getMemoryInfo(mi)
                        val ramTotal = mi.totalMem.toDouble() / (1024.0 * 1024.0 * 1024.0)
                        val ramUsed  = (mi.totalMem - mi.availMem).toDouble() / (1024.0 * 1024.0 * 1024.0)

                        // Battery
                        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                        val level   = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, 0)   ?: 0
                        val scale   = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
                        val battery = if (scale > 0) (level * 100 / scale) else 0

                        // Temperature (in tenths of degrees Celsius)
                        val tempRaw = batteryIntent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
                        val temp    = tempRaw / 10.0

                        result.success(mapOf(
                            "cpu"      to cpuPercent,
                            "ramUsed"  to ramUsed,
                            "ramTotal" to ramTotal,
                            "battery"  to battery,
                            "temp"     to temp,
                            "fps"      to 60
                        ))
                    } catch (e: Exception) {
                        result.error("STATS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Crosshair Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CROSSHAIR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCrosshair" -> {
                    if (Settings.canDrawOverlays(this)) {
                        val intent = Intent(this, CrosshairOverlayService::class.java)
                        intent.putExtra("shape", call.argument<String>("shape") ?: "cross_dot")
                        intent.putExtra("color", call.argument<String>("color") ?: "#FF0000")
                        intent.putExtra("size", call.argument<Int>("size") ?: 40)
                        intent.putExtra("opacity", call.argument<Int>("opacity") ?: 255)
                        intent.putExtra("offsetX", call.argument<Int>("offsetX") ?: 0)
                        intent.putExtra("offsetY", call.argument<Int>("offsetY") ?: 0)
                        startService(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "updateCrosshair" -> {
                    val intent = Intent(this, CrosshairOverlayService::class.java)
                    intent.putExtra("shape", call.argument<String>("shape") ?: "cross_dot")
                    intent.putExtra("color", call.argument<String>("color") ?: "#FF0000")
                    intent.putExtra("size", call.argument<Int>("size") ?: 40)
                    intent.putExtra("opacity", call.argument<Int>("opacity") ?: 255)
                    intent.putExtra("offsetX", call.argument<Int>("offsetX") ?: 0)
                    intent.putExtra("offsetY", call.argument<Int>("offsetY") ?: 0)
                    startService(intent)
                    result.success(true)
                }
                "stopCrosshair" -> {
                    stopService(Intent(this, CrosshairOverlayService::class.java))
                    result.success(true)
                }
                "isRunning" -> {
                    result.success(CrosshairOverlayService.isRunning)
                }
                "checkPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestPermission" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        val permIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:\$packageName"))
                        startActivityForResult(permIntent, OVERLAY_REQUEST_CODE)
                        result.success(false)
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Auto Clicker Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTOCLICKER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> {
                    val serviceName = "$packageName/.AutoClickerService"
                    val enabledServices = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
                    val isEnabled = enabledServices != null && enabledServices.contains(serviceName)
                    result.success(isEnabled)
                }
                "openSettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "start" -> {
                    val service = AutoClickerService.instance
                    if (service != null) {
                        val interval = call.argument<Int>("interval")?.toLong() ?: 100L
                        val xList = call.argument<List<Double>>("xList") ?: listOf(540.0)
                        val yList = call.argument<List<Double>>("yList") ?: listOf(960.0)
                        val points = mutableListOf<FloatArray>()
                        for (i in 0 until minOf(xList.size, yList.size)) {
                            points.add(floatArrayOf(xList[i].toFloat(), yList[i].toFloat()))
                        }
                        service.startClicking(interval, points)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stop" -> {
                    val service = AutoClickerService.instance
                    service?.stopClicking()
                    result.success(true)
                }
                "isRunning" -> {
                    result.success(AutoClickerService.isRunning)
                }
                "checkOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        val permIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:\$packageName"))
                        startActivityForResult(permIntent, OVERLAY_REQUEST_CODE)
                    }
                    result.success(false)
                }
                "startAutoClickerOverlay" -> {
                    if (Settings.canDrawOverlays(this)) {
                        val intent = Intent(this, AutoClickerOverlayService::class.java)
                        intent.putExtra("cps", call.argument<Int>("cps") ?: 10)
                        intent.putExtra("pointCount", call.argument<Int>("pointCount") ?: 1)
                        intent.putExtra("interval", call.argument<Int>("interval") ?: 100)
                        intent.putExtra("isShizukuMode", call.argument<Boolean>("isShizukuMode") ?: false)
                        val xList = call.argument<List<Double>>("xList") ?: listOf(540.0)
                        val yList = call.argument<List<Double>>("yList") ?: listOf(960.0)
                        intent.putExtra("xList", xList.toDoubleArray())
                        intent.putExtra("yList", yList.toDoubleArray())
                        startService(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopAutoClickerOverlay" -> {
                    stopService(Intent(this, AutoClickerOverlayService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Game Launcher Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GAME_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchGame" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            // Move Flutter activity to background so the game is in foreground
                            moveTaskToBack(true)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "getInstalledGames" -> {
                    val pm = packageManager
                    val installedApps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                    val games = mutableListOf<Map<String, Any>>()
                    val gameKeywords = listOf(
                        "game", "legend", "mobile", "pubg", "garena", "codm", "genshin",
                        "minecraft", "roblox", "valorant", "arena", "battle", "clash",
                        "war", "shoot", "race", "sport", "fifa", "nba", "moba", "rpg",
                        "pvp", "fps", "mmorpg", "br", "royale", "survival", "honor",
                        "kings", "league", "strike", "force", "duty", "impact",
                        "ff", "mlbb", "bang", "freefire", "brawl", "supercell"
                    )
                    for (app in installedApps) {
                        if (app.flags and ApplicationInfo.FLAG_SYSTEM != 0) continue
                        if (app.packageName == packageName) continue
                        val launchIntent = pm.getLaunchIntentForPackage(app.packageName) ?: continue
                        val category = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            app.category
                        } else {
                            ApplicationInfo.CATEGORY_UNDEFINED
                        }
                        val pkgLower = app.packageName.lowercase()
                        val nameLower = pm.getApplicationLabel(app).toString().lowercase()
                        val matchesKeyword = gameKeywords.any { pkgLower.contains(it) || nameLower.contains(it) }
                        val isGame = category == ApplicationInfo.CATEGORY_GAME ||
                                     (category == ApplicationInfo.CATEGORY_UNDEFINED && matchesKeyword)
                        if (isGame) {
                            games.add(mapOf(
                                "name" to pm.getApplicationLabel(app).toString(),
                                "package" to app.packageName
                            ))
                        }
                    }
                    result.success(games)
                }
                else -> result.notImplemented()
            }
        }

        // ── Red Magic Corner Channel ──────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, REDMAGIC_CORNER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCorner" -> {
                    if (android.provider.Settings.canDrawOverlays(this)) {
                        val features = call.argument<String>("allowedFeatures") ?: ""
                        val intent = Intent(this, RedMagicCornerService::class.java)
                        intent.putExtra("allowedFeatures", features)
                        startService(intent)
                        result.success(true)
                    } else {
                        // Request overlay permission
                        val permIntent = Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            android.net.Uri.parse("package:$packageName"))
                        startActivityForResult(permIntent, OVERLAY_REQUEST_CODE)
                        result.success(false)
                    }
                }
                "stopCorner" -> {
                    stopService(Intent(this, RedMagicCornerService::class.java))
                    result.success(true)
                }
                "isCornerRunning" -> {
                    result.success(RedMagicCornerService.isRunning)
                }
                "checkOverlayPermission" -> {
                    result.success(android.provider.Settings.canDrawOverlays(this))
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        this.intent = intent
        if (intent.getBooleanExtra("open_smart_touch", false)) {
            overlayChannel?.invokeMethod("showSmartTouchDashboard", null)
            intent.removeExtra("open_smart_touch")
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            startVpnService(pendingMode)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun startVpnService(mode: String) {
        val intent = Intent(this, LocalVpnService::class.java)
        intent.putExtra("mode", mode)
        startService(intent)
    }
}
