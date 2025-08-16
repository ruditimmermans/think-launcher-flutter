import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:battery_plus/battery_plus.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:think_launcher/gestures/gesture_handler.dart';
import 'package:think_launcher/models/app_info.dart';
import 'package:think_launcher/models/folder.dart';
import 'package:think_launcher/models/notification_info.dart';
import 'package:think_launcher/screens/search_screen.dart';
import 'package:think_launcher/screens/settings_screen.dart';
import 'package:think_launcher/utils/no_grow_scroll_behaviour.dart';
import 'package:think_launcher/models/weather_info.dart';
import 'package:think_launcher/services/weather_service.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/screens/reorder_apps_screen.dart';
import 'package:think_launcher/constants/dialog_options.dart';

class MainScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const MainScreen({super.key, required this.prefs});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  // Cache for app information
  static final Map<String, AppInfo> _appInfoCache = {};

  // State variables
  late List<String> _selectedApps;
  late int _numApps;
  List<Folder> _folders = [];
  final Set<String> _expandedFolders = {};

  late bool _showDateTime;
  late bool _showSearchButton;
  late bool _showSettingsButton;

  late double _appFontSize;
  late bool _enableScroll;
  late bool _showIcons;
  late String _currentTime;
  late String _currentDate;
  late int _batteryLevel;
  WeatherInfo? _weatherInfo;
  late WeatherService _weatherService;

  late double _appIconSize;

  // Notification state
  final Map<String, NotificationInfo> _notifications = {};

  void _saveNotifications() {
    final notificationsJson =
        jsonEncode(_notifications.map((key, notification) => MapEntry(
              key,
              {
                'packageName': notification.packageName,
                'title': notification.title,
                'content': notification.content,
                'id': notification.id,
              },
            )));
    widget.prefs.setString('notifications', notificationsJson);
  }

  void _loadNotifications() {
    final notificationsJson = widget.prefs.getString('notifications');
    if (notificationsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(notificationsJson);
      setState(() {
        _notifications.clear();
        decoded.forEach((key, value) {
          _notifications[key] = NotificationInfo(
            packageName: value['packageName'],
            title: value['title'],
            content: value['content'],
            id: value['id'],
          );
        });
      });
    }
  }

  // Timers
  Timer? _dateTimeTimer;
  Timer? _batteryTimer;
  Timer? _weatherTimer;
  bool _isNavigating = false;
  final Battery _battery = Battery();

  // Formatters
  static final _timeFormatter = DateFormat('HH:mm');
  static final _dateFormatter = DateFormat('EEE, dd MMM');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeState();
    _setupTimers();
    _setupBatteryListener();
    _setupNotificationListener();
    _setupWeatherService();
  }

  void _initializeState() {
    _selectedApps = widget.prefs.getStringList('selectedApps') ?? [];
    _numApps = widget.prefs.getInt('numApps') ?? 5;
    _loadFolders();
    _loadNotifications();

    _showDateTime = widget.prefs.getBool('showDateTime') ?? true;
    _showSearchButton = widget.prefs.getBool('showSearchButton') ?? true;
    _showSettingsButton = widget.prefs.getBool('showSettingsButton') ?? true;

    _appFontSize = widget.prefs.getDouble('appFontSize') ?? 18.0;
    _enableScroll = widget.prefs.getBool('enableScroll') ?? true;
    _showIcons = widget.prefs.getBool('showIcons') ?? true;

    _appIconSize = widget.prefs.getDouble('appIconSize') ?? 18.0;
    _currentTime = _timeFormatter.format(DateTime.now());
    _currentDate = _dateFormatter.format(DateTime.now());
    _batteryLevel = 0;
  }

  void _setupWeatherService() {
    _weatherService = WeatherService(
        apiKey: const String.fromEnvironment('OPENWEATHER_API_KEY'));
    _updateWeather();
  }

  void _setupTimers() {
    _dateTimeTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _updateDateTime());
    _batteryTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _updateBattery());
    _weatherTimer =
        Timer.periodic(const Duration(minutes: 30), (_) => _updateWeather());
  }

  void _setupBatteryListener() {
    _battery.onBatteryStateChanged.listen((_) => _updateBattery());
  }

  Future<void> _setupNotificationListener() async {
    // Request notification permission if not granted
    final isGranted = await NotificationListenerService.isPermissionGranted();
    if (!isGranted) {
      await NotificationListenerService.requestPermission();
    }

    // Listen to notifications
    NotificationListenerService.notificationsStream.listen((event) {
      if (!mounted) return;

      setState(() {
        if (event.hasRemoved == true) {
          _notifications.remove('${event.packageName}_${event.id}');
        } else {
          _notifications['${event.packageName}_${event.id}'] = NotificationInfo(
            packageName: event.packageName ?? '',
            title: event.title ?? '',
            content: event.content ?? '',
            id: event.id ?? 0,
          );
        }
        _saveNotifications(); // Save notifications after any change
      });
    });
  }

  void _loadFolders() {
    final foldersJson = widget.prefs.getString('folders');
    if (foldersJson != null) {
      final List<dynamic> decoded = jsonDecode(foldersJson);
      setState(() {
        _folders = decoded.map((f) => Folder.fromJson(f)).toList();
        // Remove any expanded state for folders that no longer exist
        _expandedFolders.removeWhere(
          (id) => !_folders.any((f) => f.id == id),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateTimeTimer?.cancel();
    _batteryTimer?.cancel();
    _weatherTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadFolders();
      _buildAppGrid();
      _loadNotifications();
      _updateBattery();
      _updateDateTime();
      _updateWeather();

      // Refresh app info cache to get updated custom names
      _refreshAppInfoCache();
    }
  }

  /// Refreshes the entire app info cache to get updated custom names
  Future<void> _refreshAppInfoCache() async {
    for (final packageName in _selectedApps) {
      await _refreshAppInfo(packageName);
    }
    setState(() {});
  }

  Future<AppInfo?> _getAppInfo(String packageName) async {
    if (_appInfoCache.containsKey(packageName)) {
      return _appInfoCache[packageName]!;
    }

    try {
      // Check if app is still installed
      final isInstalled = await InstalledApps.isAppInstalled(packageName);
      if (isInstalled == false) {
        // Remove from selected apps and save
        setState(() {
          _selectedApps.remove(packageName);
          widget.prefs.setStringList('selectedApps', _selectedApps);
        });
        return null;
      }

      final app = await InstalledApps.getAppInfo(packageName, null);
      final appInfo = AppInfo.fromInstalledApps(app);

      // Load custom name if exists
      final customNamesJson = widget.prefs.getString('customAppNames') ?? '{}';
      final customNames = Map<String, String>.from(jsonDecode(customNamesJson));
      final customName = customNames[packageName];

      final finalAppInfo = customName != null
          ? appInfo.copyWith(customName: customName)
          : appInfo;
      _appInfoCache[packageName] = finalAppInfo;
      return finalAppInfo;
    } catch (e) {
      if (!mounted) return null;
      debugPrint(
          AppLocalizations.of(context)!.errorGettingAppInfo(packageName));
      // Remove from selected apps and save
      setState(() {
        _selectedApps.remove(packageName);
        widget.prefs.setStringList('selectedApps', _selectedApps);
      });
      return null;
    }
  }

  Future<void> _preloadAppInfo() async {
    if (_selectedApps.isEmpty) return;
    final futures = _selectedApps
        .where((packageName) => !_appInfoCache.containsKey(packageName))
        .map((packageName) => _getAppInfo(packageName));
    await Future.wait(futures);
  }

  /// Refreshes app info cache for a specific app
  Future<void> _refreshAppInfo(String packageName) async {
    try {
      final app = await InstalledApps.getAppInfo(packageName, null);
      final appInfo = AppInfo.fromInstalledApps(app);

      // Load custom name if exists
      final customNamesJson = widget.prefs.getString('customAppNames') ?? '{}';
      final customNames = Map<String, String>.from(jsonDecode(customNamesJson));
      final customName = customNames[packageName];

      final finalAppInfo = customName != null
          ? appInfo.copyWith(customName: customName)
          : appInfo;
      _appInfoCache[packageName] = finalAppInfo;
    } catch (e) {
      debugPrint('Error refreshing app info for $packageName: $e');
    }
  }

  void _loadSettings() {
    if (!mounted) return;

    Future.microtask(() async {
      if (!mounted) return;

      final newNumApps = widget.prefs.getInt('numApps') ?? 5;

      final newShowDateTime = widget.prefs.getBool('showDateTime') ?? true;
      final newShowSearchButton =
          widget.prefs.getBool('showSearchButton') ?? true;
      final newShowSettingsButton =
          widget.prefs.getBool('showSettingsButton') ?? true;

      final newAppFontSize = widget.prefs.getDouble('appFontSize') ?? 18.0;
      final newEnableScroll = widget.prefs.getBool('enableScroll') ?? true;
      final newShowIcons = widget.prefs.getBool('showIcons') ?? false;

      final newSelectedApps = widget.prefs.getStringList('selectedApps') ?? [];
      final newAppIconSize = widget.prefs.getDouble('appIconSize') ?? 18.0;

      final hasChanges = _numApps != newNumApps ||
          _showDateTime != newShowDateTime ||
          _showSearchButton != newShowSearchButton ||
          _showSettingsButton != newShowSettingsButton ||
          _appFontSize != newAppFontSize ||
          _enableScroll != newEnableScroll ||
          _showIcons != newShowIcons ||
          !listEquals(_selectedApps, newSelectedApps) ||
          _appIconSize != newAppIconSize;

      if (hasChanges) {
        setState(() {
          _numApps = newNumApps;

          _showDateTime = newShowDateTime;
          _showSearchButton = newShowSearchButton;
          _showSettingsButton = newShowSettingsButton;

          _appFontSize = newAppFontSize;
          _enableScroll = newEnableScroll;
          _showIcons = newShowIcons;

          _selectedApps = newSelectedApps;
          _appIconSize = newAppIconSize;
        });

        final showStatusBar = widget.prefs.getBool('showStatusBar') ?? false;
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: showStatusBar
              ? [SystemUiOverlay.top, SystemUiOverlay.bottom]
              : [SystemUiOverlay.bottom],
        );

        await _preloadAppInfo();
      }
    });
  }

  void _updateDateTime() {
    if (!mounted || !_showDateTime) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = _timeFormatter.format(now);
      _currentDate = _dateFormatter.format(now);
    });
  }

  Future<void> _updateBattery() async {
    if (!mounted || !_showDateTime) return;
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() => _batteryLevel = level);
      }
    } catch (e) {
      // Error silently
    }
  }

  Future<void> _updateWeather() async {
    if (!mounted || !_showDateTime) return;
    try {
      final weather = await _weatherService.getCurrentWeather();
      if (mounted) {
        setState(() => _weatherInfo = weather);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint(AppLocalizations.of(context)!.errorUpdatingWeather);
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
          pageBuilder: (context, animation, secondaryAnimation) {
            return SettingsScreen(prefs: widget.prefs);
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      if (mounted) {
        _loadSettings();
        _loadFolders(); // Reload folders when returning from settings
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
      final autoFocus = widget.prefs.getBool('autoFocusSearch') ?? true;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return SearchScreen(
              prefs: widget.prefs,
              autoFocus: autoFocus,
            );
          },
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
    return FutureBuilder<List<AppInfo?>>(
      future: Future.wait(
        _selectedApps.map((packageName) => _getAppInfo(packageName)),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _appInfoCache.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.loading,
              style: const TextStyle(fontSize: 18),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error loading apps: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading applications',
              style: TextStyle(
                fontSize: _appFontSize,
                fontWeight: FontWeight.normal,
              ),
            ),
          );
        }

        final apps = (snapshot.data ?? [])
            .where((app) => app != null)
            .cast<AppInfo>()
            .toList();
        if (apps.isEmpty) {
          return Center(
            child: Text(
              'No applications selected',
              style: TextStyle(
                fontSize: _appFontSize,
                fontWeight: FontWeight.normal,
              ),
            ),
          );
        }

        return _buildListView(apps);
      },
    );
  }

  Widget _buildListView(List<AppInfo> apps) {
    // Create a map of package name to app info for easy lookup
    final appMap = {for (var app in apps) app.packageName: app};

    // Get list of apps not in any folder
    final appsInFolders = _folders.expand((f) => f.appPackageNames).toSet();
    final unorganizedApps =
        apps.where((app) => !appsInFolders.contains(app.packageName)).toList();

    // Build list items including folders and unorganized apps
    final items = <Widget>[];

    // Add folders
    for (final folder in _folders) {
      if (folder.appPackageNames.isNotEmpty) {
        items.add(_buildFolderItem(folder));
        if (_expandedFolders.contains(folder.id)) {
          items.addAll(
            folder.appPackageNames
                .where((packageName) => appMap.containsKey(packageName))
                .map(
                  (packageName) => Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: _buildAppItem(appMap[packageName]!),
                  ),
                ),
          );
        }
      }
    }

    // Add unorganized apps
    items.addAll(unorganizedApps.map((app) => _buildAppItem(app)));

    return ScrollConfiguration(
      behavior: NoGlowScrollBehavior(),
      child: ListView(
        padding: EdgeInsets.zero,
        physics: _enableScroll
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        children: items,
      ),
    );
  }

  Future<void> _showFolderOptionsDialog(Folder folder) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            folder.name,
            style: const TextStyle(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.editFolder),
                onTap: () => Navigator.pop(context, FolderDialogOptions.rename),
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(AppLocalizations.of(context)!.deleteFolder),
                onTap: () => Navigator.pop(context, FolderDialogOptions.delete),
              ),
              ListTile(
                leading: const Icon(Icons.reorder),
                title: Text(AppLocalizations.of(context)!.reorderAppsInFolder),
                onTap: () =>
                    Navigator.pop(context, FolderDialogOptions.reorder),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    switch (result) {
      case FolderDialogOptions.rename:
        final newName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            final controller = TextEditingController(text: folder.name);
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.editFolder),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.folderName,
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );

        if (newName != null && newName.isNotEmpty) {
          setState(() {
            final index = _folders.indexWhere((f) => f.id == folder.id);
            if (index != -1) {
              _folders[index] = folder.copyWith(name: newName);
              final foldersJson =
                  jsonEncode(_folders.map((f) => f.toJson()).toList());
              widget.prefs.setString('folders', foldersJson);
            }
          });
        }
        break;

      case FolderDialogOptions.delete:
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.deleteFolder),
              content: Text(
                AppLocalizations.of(context)!.deleteFolderConfirm(folder.name),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.deleteFolder),
                ),
              ],
            );
          },
        );

        if (shouldDelete == true) {
          setState(() {
            _folders.removeWhere((f) => f.id == folder.id);
            _expandedFolders.remove(folder.id);
            final foldersJson =
                jsonEncode(_folders.map((f) => f.toJson()).toList());
            widget.prefs.setString('folders', foldersJson);
          });
        }
        break;

      case FolderDialogOptions.reorder:
        // Navigate to reorder screen
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReorderAppsScreen(
              prefs: widget.prefs,
              folder: folder,
            ),
          ),
        );
        _loadFolders(); // Reload folders after returning from reorder screen
        break;
    }
  }

  Widget _buildFolderItem(Folder folder) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_expandedFolders.contains(folder.id)) {
              _expandedFolders.remove(folder.id);
            } else {
              _expandedFolders.add(folder.id);
            }
          });
        },
        onLongPress: () => _showFolderOptionsDialog(folder),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            minHeight: _appIconSize + 16.0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          child: Row(
            children: [
              if (_showIcons)
                Container(
                  width: _appIconSize,
                  height: _appIconSize,
                  padding: EdgeInsets.all(_appIconSize * 0.15),
                  child: Icon(
                    Icons.folder,
                    size: _appIconSize * 0.7,
                    color: Colors.grey[700],
                  ),
                ),
              if (_showIcons) const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  folder.name,
                  style: TextStyle(
                    fontSize: _appFontSize,
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Icon(
                _expandedFolders.contains(folder.id)
                    ? Icons.expand_less
                    : Icons.expand_more,
                size: 24.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAppOptionsDialog(AppInfo app) async {
    // Check if app is already in a folder
    final isInFolder = _folders
        .any((folder) => folder.appPackageNames.contains(app.packageName));

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            app.displayName,
            style: const TextStyle(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(AppLocalizations.of(context)!.appInfo),
                onTap: () => Navigator.pop(context, AppDialogOptions.info),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.renameApp),
                onTap: () => Navigator.pop(context, AppDialogOptions.rename),
              ),
              if (app.customName != null)
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: Text(AppLocalizations.of(context)!.resetAppName),
                  onTap: () =>
                      Navigator.pop(context, AppDialogOptions.resetAppName),
                ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(AppLocalizations.of(context)!.uninstallApp),
                onTap: () => Navigator.pop(context, AppDialogOptions.uninstall),
              ),
              if (!isInFolder)
                ListTile(
                  leading: const Icon(Icons.create_new_folder),
                  title: Text(AppLocalizations.of(context)!.createFolder),
                  onTap: () =>
                      Navigator.pop(context, AppDialogOptions.createFolder),
                ),
              if (_folders.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(AppLocalizations.of(context)!.moveToFolder),
                  onTap: () =>
                      Navigator.pop(context, AppDialogOptions.moveToFolder),
                ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    switch (result) {
      case AppDialogOptions.info:
        await AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:${app.packageName}',
        ).launch();
        break;
      case AppDialogOptions.uninstall:
        final shouldUninstall = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.uninstallApp),
              content: Text(
                AppLocalizations.of(context)!.confirmUninstall(app.name),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.uninstallApp),
                ),
              ],
            );
          },
        );

        if (shouldUninstall == true) {
          await InstalledApps.uninstallApp(app.packageName);
          setState(() {
            _selectedApps.remove(app.packageName);
            widget.prefs.setStringList('selectedApps', _selectedApps);
          });
        }
        break;
      case AppDialogOptions.createFolder:
        final folderName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            final controller = TextEditingController();
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.createFolder),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.folderName,
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );

        if (folderName != null && folderName.isNotEmpty) {
          final newFolder = Folder(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: folderName,
            appPackageNames: [app.packageName],
          );

          setState(() {
            _folders.add(newFolder);
            final foldersJson =
                jsonEncode(_folders.map((f) => f.toJson()).toList());
            widget.prefs.setString('folders', foldersJson);
          });
        }
        break;
      case AppDialogOptions.rename:
        final newName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            final controller = TextEditingController(text: app.displayName);
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.renameApp),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.folderName,
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );

        if (newName != null && newName.isNotEmpty && newName != app.name) {
          final updatedApp = app.copyWith(customName: newName);
          _appInfoCache[app.packageName] = updatedApp;

          // Save custom names to preferences
          final customNamesJson =
              widget.prefs.getString('customAppNames') ?? '{}';
          final customNames =
              Map<String, String>.from(jsonDecode(customNamesJson));
          customNames[app.packageName] = newName;
          widget.prefs.setString('customAppNames', jsonEncode(customNames));

          // Force refresh of the app grid to show updated names
          setState(() {});
        }
        break;
      case AppDialogOptions.resetAppName:
        // Remove custom name and reset to system name
        final updatedApp = app.copyWith(customName: null);
        _appInfoCache[app.packageName] = updatedApp;

        // Remove from custom names preferences
        final customNamesJson =
            widget.prefs.getString('customAppNames') ?? '{}';
        final customNames =
            Map<String, String>.from(jsonDecode(customNamesJson));
        customNames.remove(app.packageName);
        widget.prefs.setString('customAppNames', jsonEncode(customNames));

        // Refresh the app info to ensure system name is loaded
        await _refreshAppInfo(app.packageName);

        // Force refresh of the app grid to show updated names
        setState(() {});
        break;
      case AppDialogOptions.moveToFolder:
        // Filter out the folder the app is currently in
        final availableFolders = _folders
            .where(
                (folder) => !folder.appPackageNames.contains(app.packageName))
            .toList();

        if (availableFolders.isEmpty) {
          // Show message if no other folders available
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.moveToFolder),
                content: Text(AppLocalizations.of(context)!.noOtherFoldersAvailable),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ],
              );
            },
          );
          return;
        }

        final selectedFolder = await showDialog<Folder>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectFolder),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: availableFolders
                    .map((folder) => ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(folder.name),
                          subtitle:
                              Text('${folder.appPackageNames.length} apps'),
                          onTap: () => Navigator.pop(context, folder),
                        ))
                    .toList(),
              ),
            );
          },
        );

        if (selectedFolder != null) {
          setState(() {
            // First, remove app from any existing folder
            for (int i = 0; i < _folders.length; i++) {
              if (_folders[i].appPackageNames.contains(app.packageName)) {
                _folders[i] = _folders[i].copyWith(
                  appPackageNames: _folders[i]
                      .appPackageNames
                      .where((packageName) => packageName != app.packageName)
                      .toList(),
                );
              }
            }

            // Then add app to selected folder
            final folderIndex =
                _folders.indexWhere((f) => f.id == selectedFolder.id);
            if (folderIndex != -1) {
              _folders[folderIndex] = selectedFolder.copyWith(
                appPackageNames: [
                  ...selectedFolder.appPackageNames,
                  app.packageName
                ],
              );
            }

            // Save updated folders
            final foldersJson =
                jsonEncode(_folders.map((f) => f.toJson()).toList());
            widget.prefs.setString('folders', foldersJson);
          });
        }
        break;
    }
  }

  Widget _buildAppItem(AppInfo app) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          InstalledApps.startApp(app.packageName);
          setState(() {
            _expandedFolders.clear(); // Close all folders
          });
        },
        onLongPress: () => _showAppOptionsDialog(app),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            minHeight: _appIconSize + 16.0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: _buildListAppItem(app),
        ),
      ),
    );
  }

  Widget _buildListAppItem(AppInfo app) {
    // Find notification for this app
    final notification = _notifications.values
        .where((n) => n.packageName == app.packageName)
        .firstOrNull;

    return Row(
      children: [
        if (_showIcons && app.icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: _appIconSize,
              height: _appIconSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    // Convert to grayscale using luminance values
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Image.memory(
                    app.icon!,
                    width: _appIconSize,
                    height: _appIconSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: notification != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.displayName,
                      style: TextStyle(
                        fontSize: _appFontSize,
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: _appFontSize - 5,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                )
              : Text(
                  app.displayName,
                  style: TextStyle(
                    fontSize: _appFontSize,
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
        ),
      ],
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
    final gestureHandler = GestureHandler(
      prefs: widget.prefs,
      context: context,
    );

    return GestureDetector(
      onHorizontalDragUpdate: gestureHandler.handleHorizontalDrag,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_showDateTime)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              _currentTime,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(
                                    _currentDate,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 2.25),
                                  child: Row(
                                    children: [
                                      Icon(_getBatteryIcon(_batteryLevel),
                                          size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_batteryLevel%',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_weatherInfo != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Image.network(
                                        _weatherInfo!.iconUrl,
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.fill,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_weatherInfo!.temperature.round()}°C',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        )
                      else
                        const SizedBox(),
                      Row(
                        children: [
                          if (_showSettingsButton)
                            IconButton(
                              icon: const Icon(Icons.settings, size: 28),
                              onPressed: _openSettings,
                              padding: EdgeInsets.zero,
                            ),
                          if (_showSearchButton)
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
                      if (_selectedApps.isEmpty)
                        Center(
                          child: Text(
                            AppLocalizations.of(context)!.pressSettingsButtonToStart,
                            style: const TextStyle(fontSize: 18),
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
    );
  }
}
