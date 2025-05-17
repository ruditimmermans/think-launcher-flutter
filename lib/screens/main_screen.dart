import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../models/app_info.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'package:battery_plus/battery_plus.dart';

class MainScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const MainScreen({super.key, required this.prefs});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  List<String> selectedApps = [];
  Map<String, AppInfo> appInfoCache = {};
  int numApps = 5;
  int numColumns = 1;
  bool showDateTime = true;
  bool showSearchButton = true;
  bool showSettingsButton = true;
  bool useBoldFont = false;
  double appFontSize = 18.0;
  bool enableScroll = true;
  bool showIcons = false;
  String currentTime = '';
  String currentDate = '';
  int batteryLevel = 0;
  Timer? _dateTimeTimer;
  Timer? _batteryTimer;
  bool _isNavigating = false;
  final Battery _battery = Battery();
  bool _isFirstLoad = true;
  bool showAppTitles = true;
  double appIconSize = 18.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _updateDateTime();
    _updateBattery();
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _updateBattery();
    });
    _dateTimeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateDateTime();
    });
    _batteryTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateBattery();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateTimeTimer?.cancel();
    _batteryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only update battery and date/time
      _updateBattery();
      _updateDateTime();

      // If it's the first load, load settings
      if (_isFirstLoad) {
        _loadSettings();
        _isFirstLoad = false;
      }
    }
  }

  Future<AppInfo> _getAppInfo(String packageName) async {
    // If we already have the info in cache, return it
    if (appInfoCache.containsKey(packageName)) {
      return appInfoCache[packageName]!;
    }

    try {
      final app = await InstalledApps.getAppInfo(packageName, null);
      final appInfo = AppInfo.fromInstalledApps(app);
      appInfoCache[packageName] = appInfo;
      return appInfo;
    } catch (e) {
      debugPrint('Error getting app info for $packageName: $e');
      return AppInfo(
        name: packageName,
        packageName: packageName,
        versionName: '',
        versionCode: 0,
        builtWith: BuiltWith.unknown,
        installedTimestamp: 0,
      );
    }
  }

  Future<void> _preloadAppInfo() async {
    if (selectedApps.isEmpty) return;

    // Load apps in parallel to improve performance
    final futures = selectedApps
        .where((packageName) => !appInfoCache.containsKey(packageName))
        .map((packageName) => _getAppInfo(packageName));

    await Future.wait(futures);
  }

  void _loadSettings() {
    if (!mounted) return;

    // Load settings asynchronously
    Future.microtask(() async {
      if (!mounted) return;

      setState(() {
        numApps = widget.prefs.getInt('numApps') ?? 5;
        numColumns = widget.prefs.getInt('numColumns') ?? 1;
        showDateTime = widget.prefs.getBool('showDateTime') ?? true;
        showSearchButton = widget.prefs.getBool('showSearchButton') ?? true;
        showSettingsButton = widget.prefs.getBool('showSettingsButton') ?? true;
        useBoldFont = widget.prefs.getBool('useBoldFont') ?? false;
        appFontSize = widget.prefs.getDouble('appFontSize') ?? 18.0;
        enableScroll = widget.prefs.getBool('enableScroll') ?? true;
        showIcons = widget.prefs.getBool('showIcons') ?? false;
        showAppTitles = widget.prefs.getBool('showAppTitles') ?? true;
        selectedApps = widget.prefs.getStringList('selectedApps') ?? [];
        appIconSize = widget.prefs.getDouble('appIconSize') ?? 18.0;
      });

      // Update status bar visibility
      final showStatusBar = widget.prefs.getBool('showStatusBar') ?? false;
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: showStatusBar
            ? [SystemUiOverlay.top, SystemUiOverlay.bottom]
            : [SystemUiOverlay.bottom],
      );

      // Preload app info asynchronously
      await _preloadAppInfo();
    });
  }

  void _updateDateTime() {
    if (!mounted || !showDateTime) return;
    final now = DateTime.now();
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd, MMMM - yyyy');
    setState(() {
      currentTime = timeFormatter.format(now);
      currentDate = dateFormatter.format(now);
    });
  }

  Future<void> _updateBattery() async {
    if (!mounted || !showDateTime) return;
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          batteryLevel = level;
        });
      }
    } catch (e) {
      // Error silently
    }
  }

  Future<void> _openSettings() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      if (!mounted) return;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SettingsScreen(prefs: widget.prefs),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      if (mounted) {
        _loadSettings();
      }
    } catch (e) {
      // Error silently
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _openSearch() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      if (!mounted) return;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => SearchScreen(
            prefs: widget.prefs,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (e) {
      // Error silently
    } finally {
      _isNavigating = false;
    }
  }

  Widget _buildAppGrid() {
    return FutureBuilder<List<AppInfo>>(
      future: Future.wait(
          selectedApps.map((packageName) => _getAppInfo(packageName))),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Text(
              'Loading...',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error loading apps: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading applications',
              style: TextStyle(
                fontSize: appFontSize,
                fontWeight: useBoldFont ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }

        final apps = snapshot.data ?? [];
        if (apps.isEmpty) {
          return Center(
            child: Text(
              'No applications selected',
              style: TextStyle(
                fontSize: appFontSize,
                fontWeight: useBoldFont ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }

        if (numColumns == 1) {
          return ScrollConfiguration(
            behavior: NoGlowScrollBehavior(),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: enableScroll
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => InstalledApps.startApp(app.packageName),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: appIconSize + 16.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          if (showIcons && app.icon != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Image.memory(
                                app.icon!,
                                width: appIconSize,
                                height: appIconSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          if (showAppTitles)
                            Expanded(
                              child: Text(
                                app.name,
                                style: TextStyle(
                                  fontSize: appFontSize,
                                  fontWeight: useBoldFont
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return ScrollConfiguration(
            behavior: NoGlowScrollBehavior(),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: enableScroll
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: numColumns,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
                childAspectRatio: numColumns == 4
                    ? 0.55
                    : numColumns == 3
                        ? 0.7
                        : 0.95,
              ),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => InstalledApps.startApp(app.packageName),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Container(
                      clipBehavior: Clip.none,
                      constraints: BoxConstraints(
                        minHeight: appIconSize + appFontSize + 24.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showIcons && app.icon != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Image.memory(
                                app.icon!,
                                width: appIconSize,
                                height: appIconSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          if (showAppTitles)
                            Flexible(
                              child: Text(
                                app.name,
                                style: TextStyle(
                                  fontSize: appFontSize,
                                  fontWeight: useBoldFont
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level >= 90) return Icons.battery_full;
    if (level >= 70) return Icons.battery_6_bar;
    if (level >= 50) return Icons.battery_5_bar;
    if (level >= 30) return Icons.battery_4_bar;
    if (level >= 20) return Icons.battery_3_bar;
    if (level >= 10) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          onLongPress: _openSettings,
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (showDateTime)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTime,
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: useBoldFont
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    currentDate,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: useBoldFont
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const Text(
                                    ' | ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  Icon(
                                    _getBatteryIcon(batteryLevel),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$batteryLevel%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: useBoldFont
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          const SizedBox(),
                        Row(
                          children: [
                            if (showSettingsButton)
                              IconButton(
                                icon: const Icon(Icons.settings, size: 28),
                                onPressed: _openSettings,
                                padding: EdgeInsets.zero,
                              ),
                            if (showSearchButton)
                              IconButton(
                                icon: const Icon(Icons.search, size: 28),
                                onPressed: _openSearch,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (selectedApps.isEmpty)
                          const Center(
                            child: Text(
                              'Press the settings button to start',
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        else
                          _buildAppGrid(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Class to remove any overscroll effect (glow, stretch, bounce)
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
