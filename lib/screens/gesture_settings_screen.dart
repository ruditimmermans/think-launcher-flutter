import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import '../models/app_info.dart';

class GestureSettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const GestureSettingsScreen({super.key, required this.prefs});

  @override
  State<GestureSettingsScreen> createState() => _GestureSettingsScreenState();
}

class _GestureSettingsScreenState extends State<GestureSettingsScreen> {
  bool _enableSearchGesture = true;
  bool _autoFocusSearch = true;
  bool _enableLongPressGesture = true;
  String? _leftToRightApp;
  String? _rightToLeftApp;
  final Map<String, AppInfo> _appInfoCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _preloadAppInfo();
  }

  Future<void> _preloadAppInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_leftToRightApp != null) {
        await _getAppInfo(_leftToRightApp!);
      }
      if (_rightToLeftApp != null) {
        await _getAppInfo(_rightToLeftApp!);
      }
    } catch (e) {
      debugPrint('Error preloading app info: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<AppInfo> _getAppInfo(String packageName) async {
    if (_appInfoCache.containsKey(packageName)) {
      return _appInfoCache[packageName]!;
    }

    try {
      final app = await InstalledApps.getAppInfo(packageName, null);
      final appInfo = AppInfo.fromInstalledApps(app);
      _appInfoCache[packageName] = appInfo;
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

  void _loadSettings() {
    setState(() {
      _enableSearchGesture =
          widget.prefs.getBool('enableSearchGesture') ?? true;
      _autoFocusSearch = widget.prefs.getBool('autoFocusSearch') ?? true;
      _enableLongPressGesture =
          widget.prefs.getBool('enableLongPressGesture') ?? true;
      _leftToRightApp = widget.prefs.getString('leftToRightApp');
      _rightToLeftApp = widget.prefs.getString('rightToLeftApp');
    });
  }

  Future<void> _saveSettings() async {
    await widget.prefs.setBool('enableSearchGesture', _enableSearchGesture);
    await widget.prefs.setBool('autoFocusSearch', _autoFocusSearch);
    await widget.prefs
        .setBool('enableLongPressGesture', _enableLongPressGesture);
    if (_leftToRightApp != null) {
      await widget.prefs.setString('leftToRightApp', _leftToRightApp!);
    }
    if (_rightToLeftApp != null) {
      await widget.prefs.setString('rightToLeftApp', _rightToLeftApp!);
    }
  }

  Future<void> _selectApp(bool isLeftToRight) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GestureAppSelectionScreen(
          prefs: widget.prefs,
          selectedApp: isLeftToRight ? _leftToRightApp : _rightToLeftApp,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null && result is String) {
      setState(() {
        if (isLeftToRight) {
          _leftToRightApp = result;
        } else {
          _rightToLeftApp = result;
        }
      });
      _saveSettings();
      // Preload new selected app info
      await _getAppInfo(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSettingsButton =
        widget.prefs.getBool('showSettingsButton') ?? true;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Gestures'),
          ),
          body: _isLoading
              ? const Center(
                  child: Text(
                    'Loading...',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable search gesture'),
                      subtitle: const Text('Swipe down to open search'),
                      value: _enableSearchGesture,
                      onChanged: (value) {
                        setState(() {
                          _enableSearchGesture = value;
                        });
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Auto focus search'),
                      subtitle: const Text(
                          'Cursor will be positioned in the search field when opened'),
                      value: _autoFocusSearch,
                      onChanged: (value) {
                        setState(() {
                          _autoFocusSearch = value;
                        });
                        _saveSettings();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Enable long press gesture'),
                      subtitle: const Text('Long press to open settings'),
                      value: _enableLongPressGesture,
                      onChanged: showSettingsButton
                          ? (value) {
                              setState(() {
                                _enableLongPressGesture = value;
                              });
                              _saveSettings();
                            }
                          : null,
                    ),
                    if (!showSettingsButton)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Settings button is disabled. Enable it in settings to use this gesture.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ListTile(
                      title: const Text('Left to right app'),
                      subtitle: _leftToRightApp != null &&
                              _appInfoCache.containsKey(_leftToRightApp!)
                          ? Text(_appInfoCache[_leftToRightApp!]!.name)
                          : const Text('Not selected'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _selectApp(true),
                    ),
                    ListTile(
                      title: const Text('Right to left app'),
                      subtitle: _rightToLeftApp != null &&
                              _appInfoCache.containsKey(_rightToLeftApp!)
                          ? Text(_appInfoCache[_rightToLeftApp!]!.name)
                          : const Text('Not selected'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _selectApp(false),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class GestureAppSelectionScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final String? selectedApp;

  const GestureAppSelectionScreen({
    super.key,
    required this.prefs,
    this.selectedApp,
  });

  @override
  State<GestureAppSelectionScreen> createState() =>
      _GestureAppSelectionScreenState();
}

class _GestureAppSelectionScreenState extends State<GestureAppSelectionScreen> {
  List<AppInfo> _apps = [];
  List<AppInfo> _filteredApps = [];
  final TextEditingController _searchController = TextEditingController();
  String? _selectedApp;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedApp = widget.selectedApp;
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final installedApps = await InstalledApps.getInstalledApps(
        false, // includeSystemApps
        false, // withIcon
        '', // packageNamePrefix
      );

      final appInfos =
          installedApps.map((app) => AppInfo.fromInstalledApps(app)).toList();
      appInfos.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _apps = appInfos;
          _filteredApps = List.from(appInfos);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading apps: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading applications';
          _isLoading = false;
        });
      }
    }
  }

  void _filterApps(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredApps = List.from(_apps);
      } else {
        _filteredApps = _apps
            .where(
                (app) => app.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectApp(String packageName) {
    setState(() {
      _selectedApp = packageName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Select app'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, _selectedApp),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  showCursor: true,
                  cursorColor: Colors.black,
                  cursorWidth: 2,
                  cursorRadius: const Radius.circular(1),
                  cursorOpacityAnimates: false,
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: _filterApps,
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.black),
                  ),
                )
              else if (_isLoading)
                const Center(
                  child: Text(
                    'Loading...',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              else
                Expanded(
                  child: ScrollConfiguration(
                    behavior: NoGlowScrollBehavior(),
                    child: ListView.builder(
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        final isSelected = app.packageName == _selectedApp;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectApp(app.packageName),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      app.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.black,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
