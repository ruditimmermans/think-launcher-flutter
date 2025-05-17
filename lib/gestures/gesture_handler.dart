import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import '../screens/search_screen.dart';

class GestureHandler {
  final SharedPreferences prefs;
  final BuildContext context;

  GestureHandler({
    required this.prefs,
    required this.context,
  });

  void handleVerticalDrag(DragUpdateDetails details) {
    final enableSearchGesture = prefs.getBool('enableSearchGesture');
    if (enableSearchGesture == false) return;

    if (details.delta.dy > 0) {
      // Swipe down
      _openSearch();
    }
  }

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

  Future<void> _openSearch() async {
    final autoFocus = prefs.getBool('autoFocusSearch') ?? true;
    if (!context.mounted) return;

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SearchScreen(
          prefs: prefs,
          autoFocus: autoFocus,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
