import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';

class GestureHandler {
  final SharedPreferences prefs;
  final BuildContext context;

  GestureHandler({
    required this.prefs,
    required this.context,
  });

  void handleHorizontalDrag(DragUpdateDetails details) {
    if (details.delta.dx > 0) {
      // Left to right
      final appPackage = prefs.getString('leftToRightApp');
      if (appPackage != null) {
        InstalledApps.startApp(appPackage);
      }
    } else {
      // Right to left
      final appPackage = prefs.getString('rightToLeftApp');
      if (appPackage != null) {
        InstalledApps.startApp(appPackage);
      }
    }
  }
}
