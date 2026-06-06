package com.example.admin_sensi_booster

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

class LocalVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "STOP") {
            stopForeground(true)
            stopVpn()
            return START_NOT_STICKY
        }
        
        val mode = intent?.getStringExtra("mode") ?: "Normal"
        startForegroundServiceNotification(mode)
        startVpn(mode)
        return START_STICKY
    }

    private fun startForegroundServiceNotification(mode: String) {
        val channelId = "sensi_booster_vpn"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Sensi Booster Network",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Sensi Booster Pro")
            .setContentText("Latency Mode ($mode) Sedang Berjalan...")
            .setSmallIcon(android.R.drawable.ic_menu_preferences) // Gunakan icon bawaan sementara
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

        startForeground(1998, notification)
    }

    private fun startVpn(mode: String) {
        if (vpnInterface != null) {
            vpnInterface?.close()
            vpnInterface = null
        }

        val builder = Builder()
        builder.setSession("Sensi Booster VPN")
        
        // Virtual interface IP
        builder.addAddress("10.0.0.2", 24)
        
        if (mode == "Ultra" || mode == "Low") {
            // Set Fast DNS for Smart Route / Low Latency (Menggunakan Cloudflare & Google)
            builder.addDnsServer("1.1.1.1")
            builder.addDnsServer("1.0.0.1")
            builder.addDnsServer("8.8.8.8")
        }

        try {
            vpnInterface = builder.establish()
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    private fun stopVpn() {
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        vpnInterface = null
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
    }
}
