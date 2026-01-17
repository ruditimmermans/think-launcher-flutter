import 'package:flutter/foundation.dart';

/// Supported app theme modes.
enum AppThemeMode {
  auto,
  light,
  dark,
}

const String _kAppThemeAuto = 'auto';
const String _kAppThemeLight = 'light';
const String _kAppThemeDark = 'dark';

extension AppThemeModeStorage on AppThemeMode {
  String get storageKey {
    switch (this) {
      case AppThemeMode.auto:
        return _kAppThemeAuto;
      case AppThemeMode.light:
        return _kAppThemeLight;
      case AppThemeMode.dark:
        return _kAppThemeDark;
    }
  }
}

AppThemeMode appThemeModeFromStorage(String? value) {
  switch (value) {
    case _kAppThemeLight:
      return AppThemeMode.light;
    case _kAppThemeDark:
      return AppThemeMode.dark;
    case _kAppThemeAuto:
    default:
      return AppThemeMode.auto;
  }
}

/// Global notifier used to propagate theme changes through the app.
///
/// This is initialized in `main()` based on persisted preferences and updated
/// from settings when the user changes the theme.
final ValueNotifier<AppThemeMode> appThemeNotifier =
    ValueNotifier<AppThemeMode>(AppThemeMode.auto);

