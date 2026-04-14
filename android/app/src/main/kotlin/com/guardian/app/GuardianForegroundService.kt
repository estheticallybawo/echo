// android/app/src/main/kotlin/com/guardian/app/GuardianForegroundService.kt
//
// This keeps the Porcupine wake-word listener alive when the app is backgrounded.
// Without this, Android kills the microphone process after ~60 seconds.
//
// HOW TO USE:
// 1. Place this file at the path above (match your package name)
// 2. Register in AndroidManifest.xml (see comment in voice_recognition_service.dart)
// 3. Call GuardianForegroundServiceManager.start() from your Flutter app
//    via the method channel when VoiceRecognitionService.startListening() fires.

package com.guardian.app   // ← Change to match your actual package name

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class GuardianForegroundService : Service() {

    companion object {
        const val CHANNEL_ID     = "guardian_listening_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START   = "START_LISTENING"
        const val ACTION_STOP    = "STOP_LISTENING"

        fun start(context: Context) {
            val intent = Intent(context, GuardianForegroundService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, GuardianForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val notification = buildNotification()
                startForeground(NOTIFICATION_ID, notification)
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        // START_STICKY: if Android kills the service, restart it automatically
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Guardian Safety Listener",
                // IMPORTANCE_LOW = no sound, no pop-up, just persistent icon
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Guardian is listening for your safety phrase"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        // Tapping the notification opens the app
        val openAppIntent = packageManager
            .getLaunchIntentForPackage(packageName)
            ?.let { intent ->
                PendingIntent.getActivity(
                    this, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Guardian is listening")
            .setContentText("Say your safety phrase to activate")
            // Use a small, discreet icon — not alarming
            // Replace with your actual notification icon resource
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(openAppIntent)
            // Ongoing = cannot be swiped away by the user
            .setOngoing(true)
            // LOW priority = appears at bottom of notification shade
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}