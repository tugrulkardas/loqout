package com.tugrul.tapfocus.tapfocus_project

import android.app.Application
import android.content.SharedPreferences
import android.os.FileObserver
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.File

/**
 * Listens for intervention requests from the background watchdog isolate, then
 * brings TapFocus forward / shows the block overlay.
 *
 * Triggers (either is enough):
 * 1. Marker file written under cacheDir (`tapfocus_intervene`) — most reliable
 *    from the background Dart isolate (no MethodChannel needed).
 * 2. Flutter SharedPreferences key change — backup path.
 *
 * Mock NFC only skips the physical tap — enforcement still runs through here.
 */
class TapFocusApplication : Application() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var fileObserver: FileObserver? = null
    private var lastSeenInterveneStamp = 0L

    private val prefsListener =
        SharedPreferences.OnSharedPreferenceChangeListener { prefs, key ->
            if (key == PREF_INTERVENE_REQUEST || key == PREF_INTERVENE_REQUEST_PREFIXED) {
                val pkg = prefs.getString(PREF_INTERVENE_PKG, null)
                    ?: prefs.getString(PREF_INTERVENE_PKG_PREFIXED, null)
                mainHandler.post {
                    Log.i(TAG, "Prefs-triggered intervene for $pkg")
                    TapFocusIntervention.intervene(this, pkg)
                }
            }
        }

    override fun onCreate() {
        super.onCreate()
        instance = this

        getSharedPreferences(FLUTTER_PREFS, MODE_PRIVATE)
            .registerOnSharedPreferenceChangeListener(prefsListener)

        startInterveneFileObserver()
        startInterveneFilePoll()
    }

    fun intervene(blockedPackage: String?) {
        TapFocusIntervention.intervene(this, blockedPackage)
    }

    private fun startInterveneFileObserver() {
        try {
            val watchDir = cacheDir
            if (!watchDir.exists()) watchDir.mkdirs()

            @Suppress("DEPRECATION")
            val observer = object : FileObserver(watchDir.path, CREATE or MODIFY or CLOSE_WRITE or MOVED_TO) {
                override fun onEvent(event: Int, path: String?) {
                    if (path != INTERVENE_FILE_NAME) return
                    mainHandler.post { handleInterveneFile() }
                }
            }
            observer.startWatching()
            fileObserver = observer
            Log.i(TAG, "Watching intervene file in ${watchDir.path}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start intervene FileObserver", e)
        }
    }

    /** HyperOS sometimes drops FileObserver events — poll lastModified cheaply. */
    private fun startInterveneFilePoll() {
        mainHandler.post(object : Runnable {
            override fun run() {
                try {
                    val file = File(cacheDir, INTERVENE_FILE_NAME)
                    if (file.exists()) {
                        val stamp = file.lastModified()
                        if (stamp != 0L && stamp != lastSeenInterveneStamp) {
                            lastSeenInterveneStamp = stamp
                            handleInterveneFile()
                        }
                    }
                } catch (_: Exception) {
                }
                mainHandler.postDelayed(this, 750)
            }
        })
    }

    private fun handleInterveneFile() {
        try {
            val file = File(cacheDir, INTERVENE_FILE_NAME)
            if (!file.exists()) return
            lastSeenInterveneStamp = file.lastModified()
            val raw = file.readText().trim()
            val pkg = raw.substringBefore('|', missingDelimiterValue = raw)
                .takeIf { it.isNotBlank() }
            Log.i(TAG, "File-triggered intervene for $pkg")
            TapFocusIntervention.intervene(this, pkg)
        } catch (e: Exception) {
            Log.e(TAG, "handleInterveneFile failed", e)
            TapFocusIntervention.intervene(this, null)
        }
    }

    companion object {
        private const val TAG = "TapFocusApp"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        const val INTERVENE_FILE_NAME = "tapfocus_intervene"

        const val PREF_INTERVENE_REQUEST = "tapfocus_intervene_request"
        const val PREF_INTERVENE_REQUEST_PREFIXED = "flutter.tapfocus_intervene_request"
        const val PREF_INTERVENE_PKG = "tapfocus_intervene_pkg"
        const val PREF_INTERVENE_PKG_PREFIXED = "flutter.tapfocus_intervene_pkg"

        @Volatile
        var instance: TapFocusApplication? = null
            private set
    }
}
