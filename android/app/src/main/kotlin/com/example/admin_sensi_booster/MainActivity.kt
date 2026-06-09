package com.example.admin_sensi_booster

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val VPN_CHANNEL = "com.mfw.sensi_booster/vpn"
    private val OVERLAY_CHANNEL = "com.mfw.sensi_booster/overlay"
    private val VPN_REQUEST_CODE = 0x0F
    private val OVERLAY_REQUEST_CODE = 0x10
    private var pendingMode = "Normal"
    private var overlayChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
