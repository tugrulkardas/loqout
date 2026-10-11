package com.tugrul.tapfocus.tapfocus_project

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Brings TapFocus to the foreground when the watchdog fires an intervention.
 * Fully guarded — never throws into the system process.
 */
class FocusInterventionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            val pkg = intent?.getStringExtra(EXTRA_BLOCKED_PACKAGE)
            val app = context.applicationContext as? TapFocusApplication
            if (app != null) {
                app.intervene(pkg)
                return
            }

            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)

            launch.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
            )
            launch.putExtra(MainActivity.EXTRA_FOCUS_INTERVENTION, true)
            context.startActivity(launch)
        } catch (e: Exception) {
            Log.e("TapFocusIntervention", "Failed to intervene (non-fatal)", e)
        }
    }

    companion object {
        const val ACTION = "com.tugrul.tapfocus.ACTION_FOCUS_INTERVENTION"
        const val EXTRA_BLOCKED_PACKAGE = "blocked_package"
    }
}
