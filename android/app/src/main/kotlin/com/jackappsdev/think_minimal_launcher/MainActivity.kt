package com.jackappsdev.think_minimal_launcher

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val iconPackManager by lazy {
        IconPackManager(this)
    }

    private val powerManager by lazy {
        getSystemService(Context.POWER_SERVICE) as PowerManager
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Wake screen channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                WAKE_METHOD -> {
                    val seconds = (call.argument<Int>(WAKE_LOCK_SECONDS_PARAM) ?: 3).coerceIn(1, 10)
                    wakeScreen(seconds)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // Launcher status channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                LAUNCHER_IS_DEFAULT_METHOD -> {
                    try {
                        result.success(isDefaultLauncher())
                    } catch (e: Exception) {
                        result.error("LAUNCHER_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Icon pack discovery channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ICON_PACK_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    ICON_PACK_LIST_METHOD_NAME -> {
                        try {
                            val packs = iconPackManager.getAvailableIconPacks()
                            val response = packs.map { pack ->
                                mapOf(
                                    "packageName" to pack.packageName,
                                    "name" to pack.name
                                )
                            }
                            result.success(response)
                        } catch (e: Exception) {
                            result.error(ICON_PACK_ERROR_CODE, e.message, null)
                        }
                    }

                    ICON_PACK_ICON_METHOD_NAME -> {
                        val iconPackPackageName =
                            call.argument<String>(ARG_ICON_PACK_PACKAGE_NAME) ?: ""
                        val appPackageName =
                            call.argument<String>(ARG_APP_PACKAGE_NAME) ?: ""

                        try {
                            val bytes =
                                iconPackManager.getIconForApp(iconPackPackageName, appPackageName)
                            result.success(bytes)
                        } catch (e: Exception) {
                            result.error(ICON_PACK_ICON_ERROR_CODE, e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val WAKE_CHANNEL = "com.jackappsdev.think_minimal_launcher/wake"
        private const val WAKE_METHOD = "wakeScreen"
        private const val WAKE_LOCK_SECONDS_PARAM = "seconds"
        private const val WAKE_LOCK_TAG = "think_launcher:WakeLock"

        private const val LAUNCHER_CHANNEL = "com.jackappsdev.think_minimal_launcher/launcher"
        private const val LAUNCHER_IS_DEFAULT_METHOD = "isDefaultLauncher"

        private const val ICON_PACK_CHANNEL_NAME = "com.jackappsdev.think_minimal_launcher/icon_packs"
        private const val ICON_PACK_LIST_METHOD_NAME = "getIconPacks"
        private const val ICON_PACK_ICON_METHOD_NAME = "getIconForApp"

        private const val ICON_PACK_ERROR_CODE = "ICON_PACK_ERROR"
        private const val ICON_PACK_ICON_ERROR_CODE = "ICON_PACK_ICON_ERROR"
        private const val ARG_ICON_PACK_PACKAGE_NAME = "iconPackPackageName"
        private const val ARG_APP_PACKAGE_NAME = "appPackageName"
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

    private fun isDefaultLauncher(): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
            }
            val pm = packageManager
            val resolveInfo = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
                ?: return false
            val packageName = resolveInfo.activityInfo?.packageName ?: return false
            packageName == applicationContext.packageName
        } catch (_: Throwable) {
            false
        }
    }
}
