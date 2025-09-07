package com.desu.think_launcher

import android.os.Bundle
import android.os.PowerManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.desu.think_launcher/wake"
    private val WAKE_LOCK_METHOD = "wakeScreen"
    private val WAKE_LOCK_SECONDS_PARAM = "seconds"
    private val WAKE_LOCK_TAG = "think_launcher:WakeLock"

    private val powerManager by lazy {
        getSystemService(Context.POWER_SERVICE) as PowerManager
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                WAKE_LOCK_METHOD -> {
                    val seconds = (call.argument<Int>(WAKE_LOCK_SECONDS_PARAM) ?: 3).coerceIn(1, 10)
                    wakeScreen(seconds)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun wakeScreen(seconds: Int) {
        try {
            powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                WAKE_LOCK_TAG
            ).apply {
                acquire((seconds * 1000).toLong())
            }
        } catch (_: Throwable) {
        }
    }
}
