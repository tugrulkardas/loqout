package com.tugrul.tapfocus.tapfocus_project

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Native bridges for launcher enumeration + safe foreground intervention.
 *
 * Overlay / activity launches are fully try/caught — MIUI HyperOS must never
 * kill the Flutter engine because of a denied background popup.
 */
class MainActivity : FlutterActivity() {
    private val launcherChannel = "com.tugrul.tapfocus/launcher_apps"
    private val interventionChannel = "com.tugrul.tapfocus/intervention"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, launcherChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLauncherApps" -> {
                        try {
                            result.success(queryLauncherApps())
                        } catch (e: Exception) {
                            Log.e(TAG, "getLauncherApps failed", e)
                            result.error("LAUNCHER_QUERY_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, interventionChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensureWatchdogNotificationChannel" -> {
                        try {
                            val channelId = call.argument<String>("channelId")
                                ?: DEFAULT_WATCHDOG_CHANNEL_ID
                            ensureWatchdogNotificationChannel(channelId)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "ensureWatchdogNotificationChannel failed", e)
                            result.error("CHANNEL_FAILED", e.message, null)
                        }
                    }
                    "checkOverlay" -> {
                        try {
                            val canDraw = canDrawOverlaysSafe()
                            result.success(
                                mapOf(
                                    "canDrawOverlays" to canDraw,
                                    "canPostNotifications" to canPostNotifications(),
                                    "detail" to if (canDraw) {
                                        "granted"
                                    } else {
                                        "SYSTEM_ALERT_WINDOW not granted"
                                    }
                                )
                            )
                        } catch (e: Exception) {
                            Log.e(TAG, "checkOverlay failed", e)
                            // Never crash — report denied so Flutter can prompt.
                            result.success(
                                mapOf(
                                    "canDrawOverlays" to false,
                                    "canPostNotifications" to false,
                                    "detail" to (e.message ?: "check_failed")
                                )
                            )
                        }
                    }
                    "bringToForeground" -> {
                        try {
                            val pkg = call.argument<String>("package")
                            val ok = bringTapFocusToForegroundSafe(pkg)
                            if (ok) {
                                result.success(true)
                            } else {
                                result.error(
                                    "OVERLAY_OR_POPUP_BLOCKED",
                                    "Could not bring TapFocus forward. " +
                                        "On Xiaomi/HyperOS enable overlay + " +
                                        "\"Display pop-up windows while running in background\".",
                                    null
                                )
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "bringToForeground failed", e)
                            result.error("INTERVENTION_FAILED", e.message, null)
                        }
                    }
                    "openOverlaySettings" -> {
                        try {
                            openOverlaySettingsSafe()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "openOverlaySettings failed", e)
                            result.error("SETTINGS_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun canDrawOverlaysSafe(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(this)
            } else {
                true
            }
        } catch (e: Exception) {
            Log.w(TAG, "canDrawOverlays threw", e)
            false
        }
    }

    /**
     * Must run BEFORE flutter_background_service startForegroundService.
     * Passing a custom channelId without creating the channel causes:
     * CannotPostForegroundServiceNotificationException: Bad notification
     */
    private fun ensureWatchdogNotificationChannel(channelId: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java) ?: return
        val existing = manager.getNotificationChannel(channelId)
        if (existing != null) {
            Log.d(TAG, "Notification channel already exists: $channelId")
            return
        }

        val channel = NotificationChannel(
            channelId,
            "TapFocus Focus Watchdog",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows while a TapFocus session is actively protecting your attention"
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
        Log.d(TAG, "Created notification channel: $channelId")
    }

    /** True when the OS will allow posting the FGS notification. */
    private fun canPostNotifications(): Boolean {
        return try {
            NotificationManagerCompat.from(this).areNotificationsEnabled()
        } catch (e: Exception) {
            Log.w(TAG, "areNotificationsEnabled failed", e)
            true
        }
    }

    /**
     * Safe intervention launch. Returns false instead of throwing when MIUI
     * blocks background activity starts.
     */
    private fun bringTapFocusToForegroundSafe(blockedPackage: String?): Boolean {
        return try {
            TapFocusIntervention.intervene(applicationContext, blockedPackage)
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException bringing TapFocus forward (MIUI popup?)", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error bringing TapFocus forward", e)
            false
        }
    }

    private fun openOverlaySettingsSafe() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:$packageName")
        )
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun queryLauncherApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        @Suppress("DEPRECATION")
        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(
                launcherIntent,
                PackageManager.ResolveInfoFlags.of(0)
            )
        } else {
            pm.queryIntentActivities(launcherIntent, 0)
        }

        val results = ArrayList<Map<String, Any?>>(resolveInfos.size)
        val seen = HashSet<String>()

        for (info in resolveInfos) {
            val packageName = info.activityInfo?.packageName ?: continue
            if (packageName == this.packageName) continue
            if (!seen.add(packageName)) continue

            val appInfo: ApplicationInfo = try {
                pm.getApplicationInfo(packageName, 0)
            } catch (_: PackageManager.NameNotFoundException) {
                continue
            }

            val label = pm.getApplicationLabel(appInfo)?.toString()?.trim().orEmpty()
            if (label.isEmpty()) continue

            val iconBytes: ByteArray? = try {
                drawableToPngBytes(pm.getApplicationIcon(appInfo))
            } catch (_: Exception) {
                null
            }

            results.add(
                mapOf(
                    "packageName" to packageName,
                    "label" to label,
                    "icon" to iconBytes
                )
            )
        }

        results.sortBy { (it["label"] as String).lowercase() }
        return results
    }

    private fun drawableToPngBytes(drawable: Drawable): ByteArray {
        val bitmap = when (drawable) {
            is BitmapDrawable -> drawable.bitmap ?: drawableToBitmap(drawable)
            else -> drawableToBitmap(drawable)
        }

        val maxSide = 96
        val scaled = if (bitmap.width > maxSide || bitmap.height > maxSide) {
            val ratio = minOf(
                maxSide.toFloat() / bitmap.width,
                maxSide.toFloat() / bitmap.height
            )
            Bitmap.createScaledBitmap(
                bitmap,
                (bitmap.width * ratio).toInt().coerceAtLeast(1),
                (bitmap.height * ratio).toInt().coerceAtLeast(1),
                true
            )
        } else {
            bitmap
        }

        val stream = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.PNG, 85, stream)
        if (scaled !== bitmap) {
            scaled.recycle()
        }
        return stream.toByteArray()
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        val width = drawable.intrinsicWidth.coerceAtLeast(1)
        val height = drawable.intrinsicHeight.coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    companion object {
        private const val TAG = "TapFocusMain"
        const val EXTRA_FOCUS_INTERVENTION = "tapfocus_focus_intervention"
        const val DEFAULT_WATCHDOG_CHANNEL_ID = "tapfocus_watchdog_channel"
    }
}
