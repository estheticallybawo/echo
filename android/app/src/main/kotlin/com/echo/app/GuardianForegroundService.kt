
// USED BY        : feature/audio-capture, feature/voice-activation
// ─────────────────────────────────────────────────────────────────────────────
//
// WHY THIS EXISTS
// ───────────────
// Android 8+ (API 26) blocks any background microphone use unless it runs
// inside a Foreground Service with a visible persistent notification.
// Without this service, Android kills audio capture ~1 minute after the
// app is backgrounded — Guardian would go deaf exactly when it's most needed.
//
// HOW IT WORKS
// ────────────
// 1. Flutter calls BackgroundServiceManager.startService() on app launch
// 2. BackgroundServiceManager sends "startService" via MethodChannel
// 3. This service starts, shows the "Guardian is active" notification
// 4. Android now allows continuous microphone use in the background
// 5. AudioRecorderService and VoiceRecognitionService run normally
//
// MANIFEST ADDITIONS REQUIRED
// ────────────────────────────
// In android/app/src/main/AndroidManifest.xml:
//
//   Inside <manifest>:
//     <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
//     <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
//     <uses-permission android:name="android.permission.RECORD_AUDIO"/>
//     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//
//   Inside <application>:
//     <service
//       android:name=".GuardianForegroundService"
//       android:enabled="true"
//       android:exported="false"
//       android:foregroundServiceType="microphone"/>
//
// CALL FROM MAINACTIVITY
// ───────────────────────
// In android/app/src/main/kotlin/com/guardian/app/MainActivity.kt:
//
//   override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//     super.configureFlutterEngine(flutterEngine)
//     GuardianServiceChannel.register(this, flutterEngine)
//   }
// ─────────────────────────────────────────────────────────────────────────────

package com.example.echo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val TAG          = "GuardianFgService"
private const val CHANNEL_ID   = "guardian_listening_channel"
private const val NOTIF_ID     = 1001

/// MethodChannel name — must match BackgroundServiceManager.dart exactly.
const val FOREGROUND_CHANNEL   = "com.guardian.app/foreground_service"

// ─────────────────────────────────────────────────────────────────────────────

class GuardianForegroundService : Service() {

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate")
        createNotificationChannel()
    }

    /**
     * START_STICKY: if the OS kills this service under memory pressure,
     * Android automatically restarts it. Critical for a safety app.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand — acquiring mic foreground lock")
        // Must call startForeground() within 5 seconds of onStartCommand.
        // Failure causes an ANR (Application Not Responding) crash.
        startForeground(NOTIF_ID, buildNotification())
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null // not a bound service

    override fun onDestroy() {
        super.onDestroy()
        stopForeground(STOP_FOREGROUND_REMOVE)
        Log.d(TAG, "onDestroy — mic released")
    }

    // ── Notification ──────────────────────────────────────────────────────────

    /**
     * Create the notification channel for Android 8+.
     * IMPORTANCE_LOW = no sound, no popup. Silent persistent bar indicator.
     * This is correct for a background safety service.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Guardian Safety",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Guardian is listening for your safety phrase."
                setShowBadge(false) // no badge on app icon
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    /**
     * The persistent notification required by Android policy for any app
     * that uses the microphone in the background.
     *
     * This notification:
     *   • Cannot be dismissed by the user while service runs
     *   • Opens the app when tapped
     *   • Shows no sound or vibration (PRIORITY_LOW + setSilent)
     */
    private fun buildNotification(): Notification {
        val openIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            // FLAG_IMMUTABLE required on Android 12+ (API 31).
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Guardian is active")
            .setContentText("Listening for your safety phrase.")
            // ic_guardian_notification must be a white/transparent PNG in
            // android/app/src/main/res/drawable/ic_guardian_notification.png
            .setSmallIcon(R.drawable.ic_guardian_notification)
            .setContentIntent(openIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)    // user cannot swipe away
            .setSilent(true)     // no sound
            .build()
    }

    // ── Companion: start/stop helpers ─────────────────────────────────────────

    companion object {
        /**
         * Start the service. Called from GuardianServiceChannel on "startService".
         * Uses startForegroundService() on Android 8+ as required.
         */
        fun start(ctx: Context) {
            val intent = Intent(ctx, GuardianForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ctx.startForegroundService(intent)
            } else {
                ctx.startService(intent)
            }
            Log.d(TAG, "start() called")
        }

        /** Stop the service. Called from GuardianServiceChannel on "stopService". */
        fun stop(ctx: Context) {
            ctx.stopService(Intent(ctx, GuardianForegroundService::class.java))
            Log.d(TAG, "stop() called")
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// METHOD CHANNEL BRIDGE
// Register this in MainActivity.configureFlutterEngine()
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Bridges Flutter → Android for foreground service control.
 *
 * In MainActivity.kt:
 *   override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
 *     super.configureFlutterEngine(flutterEngine)
 *     GuardianServiceChannel.register(this, flutterEngine)
 *   }
 */
object GuardianServiceChannel {
    fun register(ctx: Context, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, FOREGROUND_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> { GuardianForegroundService.start(ctx); result.success(null) }
                    "stopService"  -> { GuardianForegroundService.stop(ctx);  result.success(null) }
                    else           -> result.notImplemented()
                }
            }
        Log.d(TAG, "MethodChannel registered: $FOREGROUND_CHANNEL")
    }
}