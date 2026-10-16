package com.tugrul.tapfocus.tapfocus_project

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Brings TapFocus to the foreground and/or shows a SYSTEM_ALERT_WINDOW block
 * overlay when the watchdog detects a blocked app.
 */
object TapFocusIntervention {
    private const val TAG = "TapFocusIntervene"
    private const val DEBOUNCE_MS = 1200L

    private val mainHandler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null
    private var lastInterveneAt = 0L

    fun intervene(context: Context, blockedPackage: String?) {
        val now = SystemClock.uptimeMillis()
        if (now - lastInterveneAt < DEBOUNCE_MS) {
            Log.d(TAG, "Debounced intervene for $blockedPackage")
            return
        }
        lastInterveneAt = now

        val appContext = context.applicationContext
        Log.i(TAG, "Intervention requested for package=$blockedPackage")
        bringAppToForeground(appContext)
        maybeShowBlockOverlay(appContext, blockedPackage)
    }

    private fun bringAppToForeground(context: Context) {
        try {
            // Do not use the launcher intent. It carries RESET_TASK_IF_NEEDED,
            // which restarts Flutter at the home screen and drops the lock UI
            // while the watchdog keeps blocking.
            val launch = Intent(context, MainActivity::class.java)
            launch.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
            launch.putExtra(MainActivity.EXTRA_FOCUS_INTERVENTION, true)
            context.startActivity(launch)
            Log.i(TAG, "startActivity issued")
        } catch (e: Exception) {
            Log.e(TAG, "bringAppToForeground failed", e)
        }
    }

    private fun maybeShowBlockOverlay(context: Context, blockedPackage: String?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            Log.w(TAG, "Overlay permission missing — cannot draw block screen")
            return
        }

        try {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            dismissOverlay(wm)

            val density = context.resources.displayMetrics.density
            val pad = (24 * density).toInt()

            val column = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(Color.parseColor("#F0FFFFFF"))
                setPadding(pad, pad * 2, pad, pad)
                gravity = Gravity.CENTER
            }

            val title = TextView(context).apply {
                text = "LoqOut session active"
                textSize = 22f
                setTextColor(Color.parseColor("#1B5E20"))
                gravity = Gravity.CENTER
            }
            val body = TextView(context).apply {
                text = if (blockedPackage.isNullOrBlank()) {
                    "That app is locked during your LoqOut session."
                } else {
                    "$blockedPackage is locked.\nReturn to LoqOut to continue focusing."
                }
                textSize = 15f
                setTextColor(Color.parseColor("#333333"))
                gravity = Gravity.CENTER
                setPadding(0, pad / 2, 0, pad)
            }
            val button = Button(context).apply {
                text = "Return to LoqOut"
                setOnClickListener {
                    bringAppToForeground(context)
                    dismissOverlay(wm)
                }
            }

            column.addView(title)
            column.addView(body)
            column.addView(button)

            val root = FrameLayout(context).apply {
                setBackgroundColor(Color.parseColor("#E6121212"))
                addView(
                    column,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT,
                        Gravity.CENTER
                    )
                )
                setOnClickListener {
                    bringAppToForeground(context)
                    dismissOverlay(wm)
                }
            }

            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                type,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR,
                PixelFormat.TRANSLUCENT
            )
            params.gravity = Gravity.CENTER

            wm.addView(root, params)
            overlayView = root
            Log.i(TAG, "Block overlay shown")

            mainHandler.postDelayed({ dismissOverlay(wm) }, 4500)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show block overlay", e)
        }
    }

    private fun dismissOverlay(wm: WindowManager) {
        try {
            overlayView?.let { wm.removeView(it) }
        } catch (_: Exception) {
        } finally {
            overlayView = null
        }
    }
}
