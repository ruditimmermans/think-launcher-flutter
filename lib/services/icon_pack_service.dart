import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/models/app_info.dart';

class IconPackService {
  static const MethodChannel _channel = MethodChannel('com.desu.think_launcher/icon_packs');

  static Future<Uint8List?> _getIconBytes(
    String iconPackPackageName,
    String appPackageName,
  ) async {
    if (iconPackPackageName.isEmpty || appPackageName.isEmpty) return null;

    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'getIconForApp',
        {
          'iconPackPackageName': iconPackPackageName,
          'appPackageName': appPackageName,
        },
      );
      return bytes;
    } on PlatformException catch (e) {
      debugPrint('IconPackService error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('IconPackService unknown error: $e');
      return null;
    }
  }

  /// Returns [app] with its icon replaced by the icon from the selected icon pack,
  /// if one is configured and an override icon exists for this app.
  static Future<AppInfo> applyIconPackToApp(
    AppInfo app,
    SharedPreferences prefs,
  ) async {
    final iconPackPackageName = prefs.getString('iconPackPackageName');
    if (iconPackPackageName == null || iconPackPackageName.isEmpty) {
      return app;
    }

    final overrideBytes = await _getIconBytes(iconPackPackageName, app.packageName);
    if (overrideBytes == null) return app;

    return app.copyWith(icon: overrideBytes);
  }
}
