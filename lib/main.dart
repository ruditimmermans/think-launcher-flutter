import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/constants/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/nux_screen.dart';
import 'l10n/l10n.dart';

// Theme constants
const _kPrimaryColor = Colors.black;
const _kSurfaceColor = Colors.white;
const _kBorderRadius = 12.0;
const _kBorderWidth = 1.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Initialize theme from persisted settings.
  appThemeNotifier.value =
      appThemeModeFromStorage(prefs.getString('appTheme'));

  _configureSystemUI(prefs);
  runApp(MyApp(prefs: prefs));
}

void _configureSystemUI(SharedPreferences prefs) {
  final showStatusBar = prefs.getBool('showStatusBar') ?? false;
  final themeMode = appThemeModeFromStorage(prefs.getString('appTheme'));
  final brightness = switch (themeMode) {
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
    AppThemeMode.auto =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };
  final bool isDark = brightness == Brightness.dark;
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: showStatusBar
        ? [SystemUiOverlay.top, SystemUiOverlay.bottom]
        : [SystemUiOverlay.bottom],
  );

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: isDark ? Colors.black : _kSurfaceColor,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final showNux = !(prefs.getBool('nuxCompleted') ?? false);
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, appTheme, _) {
        final themeMode = _toFlutterThemeMode(appTheme);
        return MaterialApp(
          title: 'Think Launcher',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.all,
          home: showNux ? NuxScreen(prefs: prefs) : MainScreen(prefs: prefs),
        );
      },
    );
  }

  ThemeMode _toFlutterThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.auto:
        return ThemeMode.system;
    }
  }

  ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color primary = isDark ? Colors.white : _kPrimaryColor;
    final Color surface = isDark ? Colors.black : _kSurfaceColor;

    final ColorScheme colorScheme = isDark
        ? const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            secondary: Colors.white,
            onSecondary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
            error: Colors.red,
            onError: Colors.black,
            surfaceContainerHighest: Colors.black,
            onSurfaceVariant: Colors.white,
            outline: Colors.white,
            outlineVariant: Colors.white,
          )
        : const ColorScheme.light(
            primary: _kPrimaryColor,
            onPrimary: _kSurfaceColor,
            secondary: _kPrimaryColor,
            onSecondary: _kSurfaceColor,
            surface: _kSurfaceColor,
            onSurface: _kPrimaryColor,
            error: _kPrimaryColor,
            onError: _kSurfaceColor,
            surfaceContainerHighest: _kSurfaceColor,
            onSurfaceVariant: _kPrimaryColor,
            outline: _kPrimaryColor,
            outlineVariant: _kPrimaryColor,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(_kBorderRadius)),
          side: BorderSide(color: primary, width: _kBorderWidth),
        ),
      ),
      iconTheme: IconThemeData(color: primary),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: primary),
        bodyMedium: TextStyle(color: primary),
        titleLarge: TextStyle(color: primary),
      ),
      dividerTheme: DividerThemeData(color: primary),
      listTileTheme: ListTileThemeData(
        textColor: primary,
        iconColor: primary,
      ),
      filledButtonTheme: _buildFilledButtonTheme(primary, surface),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primary),
      textButtonTheme: _buildTextButtonTheme(primary),
      inputDecorationTheme: _buildInputDecorationTheme(primary, surface),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
        },
      ),
    );
  }

  FilledButtonThemeData _buildFilledButtonTheme(
      Color primary, Color surface) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
        ),
      ),
    );
  }

  OutlinedButtonThemeData _buildOutlinedButtonTheme(Color primary) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
        ),
      ),
    );
  }

  TextButtonThemeData _buildTextButtonTheme(Color primary) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
      ),
    );
  }

  InputDecorationTheme _buildInputDecorationTheme(
      Color primary, Color surface) {
    return InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: _buildInputBorder(primary: primary),
      enabledBorder: _buildInputBorder(primary: primary),
      focusedBorder: _buildInputBorder(primary: primary, width: 2),
      errorBorder: _buildInputBorder(primary: primary),
      focusedErrorBorder: _buildInputBorder(primary: primary, width: 2),
    );
  }

  OutlineInputBorder _buildInputBorder({
    required Color primary,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kBorderRadius),
      borderSide: BorderSide(color: primary, width: width),
    );
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
