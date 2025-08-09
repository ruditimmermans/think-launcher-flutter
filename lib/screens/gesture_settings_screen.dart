import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/utils/no_grow_scroll_behaviour.dart';
import '../models/app_info.dart';

// Theme and style constants
const _kFontSize = 18.0;
const _kSubtitleFontSize = 12.0;
const _kPadding = EdgeInsets.all(16.0);


class GestureSettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const GestureSettingsScreen({super.key, required this.prefs});

  @override
  State<GestureSettingsScreen> createState() => _GestureSettingsScreenState();
}

class _GestureSettingsScreenState extends State<GestureSettingsScreen> {
  bool _enableSearchGesture = true;
  bool _autoFocusSearch = true;

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

      _leftToRightApp = widget.prefs.getString('leftToRightApp');
      _rightToLeftApp = widget.prefs.getString('rightToLeftApp');
    });
  }

  Future<void> _saveSettings() async {
    await widget.prefs.setBool('enableSearchGesture', _enableSearchGesture);
    await widget.prefs.setBool('autoFocusSearch', _autoFocusSearch);

    if (_leftToRightApp != null) {
      await widget.prefs.setString('leftToRightApp', _leftToRightApp!);
    }
    if (_rightToLeftApp != null) {
      await widget.prefs.setString('rightToLeftApp', _rightToLeftApp!);
    }
  }

  void _removeApp(bool isLeftToRight) {
    setState(() {
      if (isLeftToRight) {
        _leftToRightApp = null;
        widget.prefs.remove('leftToRightApp');
      } else {
        _rightToLeftApp = null;
        widget.prefs.remove('rightToRightApp');
      }
    });
    _saveSettings();
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


    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.gesturesTitle),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.loading,
                    style: const TextStyle(fontSize: _kFontSize),
                  ),
                )
              : Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                  ),
                  child: ScrollConfiguration(
                    behavior: NoGlowScrollBehavior(),
                    child: ListView(
                      physics: const ClampingScrollPhysics(),
                      children: [
                        SwitchListTile(
                          title: Text(
                            AppLocalizations.of(context)!.enableSearchGestures,
                            style: const TextStyle(
                              fontSize: _kFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            AppLocalizations.of(context)!.swipeDown,
                            style: const TextStyle(fontSize: _kSubtitleFontSize),
                          ),
                          value: _enableSearchGesture,
                          onChanged: (value) {
                            setState(() {
                              _enableSearchGesture = value;
                            });
                            _saveSettings();
                          },
                        ),
                        SwitchListTile(
                          title: Text(
                            AppLocalizations.of(context)!.autoFocusSearch,
                            style: const TextStyle(
                              fontSize: _kFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            AppLocalizations.of(context)!.autoFocusSearchDescription,
                            style: const TextStyle(fontSize: _kSubtitleFontSize),
                          ),
                          value: _autoFocusSearch,
                          onChanged: (value) {
                            setState(() {
                              _autoFocusSearch = value;
                            });
                            _saveSettings();
                          },
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(context)!.leftToRightApp,
                            style: const TextStyle(
                              fontSize: _kFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: _leftToRightApp != null &&
                                  _appInfoCache.containsKey(_leftToRightApp!)
                              ? Text(
                                  _appInfoCache[_leftToRightApp!]!.name,
                                  style: const TextStyle(
                                      fontSize: _kSubtitleFontSize),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.notSelected,
                                  style: const TextStyle(fontSize: _kSubtitleFontSize),
                                ),
                          trailing: _leftToRightApp != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _removeApp(true),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () => _selectApp(true),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(context)!.swipeRight,
                            style: const TextStyle(
                              fontSize: _kFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: _rightToLeftApp != null &&
                                  _appInfoCache.containsKey(_rightToLeftApp!)
                              ? Text(
                                  _appInfoCache[_rightToLeftApp!]!.name,
                                  style: const TextStyle(
                                      fontSize: _kSubtitleFontSize),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.notSelected,
                                  style: const TextStyle(fontSize: _kSubtitleFontSize),
                                ),
                          trailing: _rightToLeftApp != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _removeApp(false),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () => _selectApp(false),
                        ),
                      ],
                    ),
                  ),
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
        false, // excludeSystemApps
        false, // withIcon
        '', // packageNamePrefix
      );

      final appInfos = installedApps.map((app) => AppInfo.fromInstalledApps(app)).toList();
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
          _errorMessage = AppLocalizations.of(context)!.errorLoadingApps;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.selectAppTitle),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: _kPadding,
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  showCursor: true,
                  cursorColor: Colors.black,
                  cursorWidth: 2,
                  cursorRadius: const Radius.circular(1),
                  cursorOpacityAnimates: false,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchAppsHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: _filterApps,
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.loading,
                          style: const TextStyle(fontSize: _kFontSize),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: _kFontSize),
                            ),
                          )
                        : ScrollConfiguration(
                            behavior: NoGlowScrollBehavior(),
                            child: ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              itemCount: _filteredApps.length,
                              itemBuilder: (context, index) {
                                final app = _filteredApps[index];
                                final isSelected =
                                    app.packageName == _selectedApp;
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context, app.packageName);
                                    },
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
                                                fontSize: _kFontSize,
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
