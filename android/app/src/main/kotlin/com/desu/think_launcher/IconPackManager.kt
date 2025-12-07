package com.desu.think_launcher

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.util.Log
import android.util.Xml
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserException
import java.io.ByteArrayOutputStream
import java.io.IOException

/**
 * Helper to discover installed icon packs and load icons for specific apps.
 * Based on the Lime Launcher IconPackManager:
 */
class IconPackManager(private val context: Context) {

    private val pm: PackageManager = context.packageManager
    private val flag: Int = PackageManager.GET_META_DATA

    // Common intent actions used by popular icon packs
    private val themes = listOf(
        "org.adw.launcher.THEMES",
        "com.gau.go.launcherex.theme"
    )

    data class IconPack(
        val packageName: String,
        val name: String
    )

    /**
     * Lazily parsed icon packs cache (appfilter.xml & drawables map).
     */
    private val parsedPacks = mutableMapOf<String, ParsedIconPack>()

    /**
     * Returns a list of installed icon packs.
     * Each entry contains the package name and user-visible label.
     */
    fun getAvailableIconPacks(): List<IconPack> {
        val result = mutableMapOf<String, IconPack>() // avoid duplicates

        for (action in themes) {
            val intent = Intent(action)

            val activities = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.queryIntentActivities(
                    intent,
                    PackageManager.ResolveInfoFlags.of(flag.toLong())
                )
            } else {
                @Suppress("DEPRECATION")
                pm.queryIntentActivities(intent, flag)
            }

            for (info in activities) {
                val iconPackPackageName = info.activityInfo.packageName
                if (result.containsKey(iconPackPackageName)) continue

                try {
                    val appInfo: ApplicationInfo? =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            pm.getApplicationInfo(
                                iconPackPackageName,
                                PackageManager.ApplicationInfoFlags.of(flag.toLong())
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            pm.getApplicationInfo(iconPackPackageName, flag)
                        }

                    if (appInfo != null) {
                        val label = pm.getApplicationLabel(appInfo).toString()
                        result[iconPackPackageName] = IconPack(
                            packageName = iconPackPackageName,
                            name = label
                        )
                    }
                } catch (_: Exception) {
                    // Ignore invalid / missing packages
                }
            }
        }

        return result.values.sortedBy { it.name.lowercase() }
    }

    /**
     * Loads the icon from the given icon pack for the given app package name.
     * @return PNG bytes for the icon, or null if no matching icon is found.
     */
    fun getIconForApp(iconPackPackageName: String, appPackageName: String): ByteArray? {
        if (iconPackPackageName.isBlank() || appPackageName.isBlank()) return null

        val parsedPack = try {
            parsedPacks.getOrPut(iconPackPackageName) {
                ParsedIconPack(iconPackPackageName)
            }
        } catch (e: Exception) {
            Log.d("IconPackManager", "Error creating ParsedIconPack: ${e.message}")
            return null
        }

        val drawable = parsedPack.getDrawableForApp(appPackageName) ?: return null
        val bitmap = drawableToBitmap(drawable) ?: return null
        return bitmapToPng(bitmap)
    }

    /**
     * Parsed icon pack that reads appfilter.xml and maps components to drawables.
     */
    private inner class ParsedIconPack(private val packageName: String) {
        private val drawables = hashMapOf<String?, String?>()
        private val iconPackRes = pm.getResourcesForApplication(packageName)

        init {
            try {
                iconPackRes.assets.open("appfilter.xml").use { input ->
                    Xml.newPullParser().run {
                        setInput(input.reader())
                        var eventType = eventType
                        while (eventType != XmlPullParser.END_DOCUMENT) {
                            if (eventType == XmlPullParser.START_TAG && name == "item") {
                                val componentValue = getAttributeValue(null, "component")
                                if (!drawables.containsKey(componentValue)) {
                                    drawables[componentValue] =
                                        getAttributeValue(null, "drawable")
                                }
                            }
                            eventType = next()
                        }
                    }
                }
            } catch (e: XmlPullParserException) {
                Log.d("IconPackManager", "Cannot parse icon pack appfilter.xml: ${e.message}")
            } catch (e: IOException) {
                Log.d("IconPackManager", "IO error reading appfilter.xml: ${e.message}")
            } catch (e: Exception) {
                Log.d("IconPackManager", "Unknown error parsing appfilter.xml: ${e.message}")
            }
        }

        @SuppressLint("UseCompatLoadingForDrawables")
        fun getDrawableForApp(appPackageName: String): Drawable? {
            val component = pm.getLaunchIntentForPackage(appPackageName)?.component
            val key = component?.toString()
            val drawableValue = drawables[key]

            if (!drawableValue.isNullOrEmpty()) {
                val id = iconPackRes.getIdentifier(drawableValue, "drawable", packageName)
                if (id > 0) {
                    return iconPackRes.getDrawable(id, null)
                }
            }
            return null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap? {
        return if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 192
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 192
            try {
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bitmap
            } catch (e: Exception) {
                Log.d("IconPackManager", "Error converting drawable to bitmap: ${e.message}")
                null
            }
        }
    }

    private fun bitmapToPng(bitmap: Bitmap): ByteArray? {
        return try {
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            Log.d("IconPackManager", "Error converting bitmap to PNG: ${e.message}")
            null
        }
    }
}
