import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/models/app_info.dart';
import 'package:think_launcher/utils/no_grow_scroll_behaviour.dart';
import 'app_selection_screen.dart';
import 'gesture_settings_screen.dart';
import 'folder_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int numApps = 5;
  bool showDateTime = true;
  bool showSearchButton = true;
  bool showSettingsButton = true;
  bool useBoldFont = false;
  double appFontSize = 18.0;
  double appIconSize = 35.0;
  bool enableScroll = true;
  bool showIcons = false;

  List<String> selectedApps = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      numApps = widget.prefs.getInt('numApps') ?? 5;
      showDateTime = widget.prefs.getBool('showDateTime') ?? true;
      showSearchButton = widget.prefs.getBool('showSearchButton') ?? true;
      showSettingsButton = widget.prefs.getBool('showSettingsButton') ?? true;
      useBoldFont = widget.prefs.getBool('useBoldFont') ?? false;
      appFontSize = widget.prefs.getDouble('appFontSize') ?? 18.0;
      appIconSize = widget.prefs.getDouble('appIconSize') ?? 35.0;
      enableScroll = widget.prefs.getBool('enableScroll') ?? true;
      showIcons = widget.prefs.getBool('showIcons') ?? true;
      selectedApps = widget.prefs.getStringList('selectedApps') ?? [];

      // Check if both are disabled and enable settings button if necessary
      final enableLongPressGesture =
          widget.prefs.getBool('enableLongPressGesture') ?? true;
      if (!showSettingsButton && !enableLongPressGesture) {
        showSettingsButton = true;
        widget.prefs.setBool('showSettingsButton', true);
      }
    });
  }

  Future<void> _saveSettings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Validate that there are no more selected apps than the maximum number
      if (selectedApps.length > numApps) {
        selectedApps = selectedApps.sublist(0, numApps);
      }

      // Check if both are disabled and enable settings button if necessary
      final enableLongPressGesture =
          widget.prefs.getBool('enableLongPressGesture') ?? true;
      if (!showSettingsButton && !enableLongPressGesture) {
        showSettingsButton = true;
      }

      await widget.prefs.setInt('numApps', numApps);
      await widget.prefs.setBool('showDateTime', showDateTime);
      await widget.prefs.setBool('showSearchButton', showSearchButton);
      await widget.prefs.setBool('showSettingsButton', showSettingsButton);
      await widget.prefs.setBool('useBoldFont', useBoldFont);
      await widget.prefs.setDouble('appFontSize', appFontSize);
      await widget.prefs.setDouble('appIconSize', appIconSize);
      await widget.prefs.setBool('enableScroll', enableScroll);
      await widget.prefs.setBool('showIcons', showIcons);
      await widget.prefs.setStringList('selectedApps', selectedApps);

      // Update status bar visibility
      final showStatusBar = widget.prefs.getBool('showStatusBar') ?? false;
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: showStatusBar
            ? [SystemUiOverlay.top, SystemUiOverlay.bottom]
            : [SystemUiOverlay.bottom],
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        setState(() {
          errorMessage = AppLocalizations.of(context)!.errorSavingSettings;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _selectApps() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AppSelectionScreen(
          prefs: widget.prefs,
          selectedApps: selectedApps,
          maxApps: numApps,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        selectedApps = result;
      });
    }
  }

  Future<void> _reorderApps() async {
    if (selectedApps.isEmpty) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReorderAppsScreen(
          selectedApps: selectedApps,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        selectedApps = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enableLongPressGesture =
        widget.prefs.getBool('enableLongPressGesture') ?? true;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.settingsTitle),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: FilledButton.tonal(
                  onPressed: _saveSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Theme(
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
                      // 1. Show date, time and battery
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showDateTimeAndBattery,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: showDateTime,
                        onChanged: (value) {
                          setState(() {
                            showDateTime = value;
                          });
                        },
                      ),

                      // 2. Show search button
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showSearchButton,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: showSearchButton,
                        onChanged: (value) {
                          setState(() {
                            showSearchButton = value;
                          });
                        },
                      ),

                      // 3. Show settings button
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showSettingsButton,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: showSettingsButton,
                        onChanged: !enableLongPressGesture
                            ? null
                            : (value) {
                                setState(() {
                                  showSettingsButton = value;
                                });
                              },
                      ),
                      if (!enableLongPressGesture)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!.longPressGestureDisabled,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      // 4. Use bold font
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.useBoldFont,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: useBoldFont,
                        onChanged: (value) {
                          setState(() {
                            useBoldFont = value;
                          });
                        },
                      ),

                      // 5. Enable list scrolling
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.enableListScrolling,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: enableScroll,
                        onChanged: (value) {
                          setState(() {
                            enableScroll = value;
                          });
                        },
                      ),

                      // 6. Show status bar
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showStatusBar,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: widget.prefs.getBool('showStatusBar') ?? false,
                        onChanged: (value) {
                          setState(() {
                            widget.prefs.setBool('showStatusBar', value);
                          });
                        },
                      ),

                      // 7. Show icons
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showIcons,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: showIcons,
                        onChanged: (value) {
                          setState(() {
                            showIcons = value;
                          });
                        },
                      ),

                      // 8. Number of apps
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.numberOfApps,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: numApps > 1
                                  ? () {
                                      setState(() {
                                        numApps--;
                                        if (selectedApps.length > numApps) {
                                          selectedApps =
                                              selectedApps.sublist(0, numApps);
                                        }
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayShape: SliderComponentShape.noOverlay,
                                  valueIndicatorColor: Colors.transparent,
                                  valueIndicatorTextStyle:
                                      const TextStyle(color: Colors.black),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                    elevation: 0,
                                    pressedElevation: 0,
                                  ),
                                  trackHeight: 2,
                                  activeTrackColor: Colors.black,
                                  inactiveTrackColor: Colors.grey,
                                  thumbColor: Colors.black,
                                  overlayColor: Colors.transparent,
                                ),
                                child: Slider(
                                  value: numApps.toDouble(),
                                  min: 1,
                                  max: 30,
                                  divisions: 29,
                                  label: numApps.toString(),
                                  onChanged: (value) {
                                    setState(() {
                                      numApps = value.toInt();
                                      if (selectedApps.length > numApps) {
                                        selectedApps =
                                            selectedApps.sublist(0, numApps);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: numApps < 30
                                  ? () {
                                      setState(() {
                                        numApps++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),

                      // 9. App font size
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.appFontSize,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: appFontSize > 14
                                  ? () {
                                      setState(() {
                                        appFontSize--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayShape: SliderComponentShape.noOverlay,
                                  valueIndicatorColor: Colors.transparent,
                                  valueIndicatorTextStyle:
                                      const TextStyle(color: Colors.black),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                    elevation: 0,
                                    pressedElevation: 0,
                                  ),
                                  trackHeight: 2,
                                  activeTrackColor: Colors.black,
                                  inactiveTrackColor: Colors.grey,
                                  thumbColor: Colors.black,
                                  overlayColor: Colors.transparent,
                                ),
                                child: Slider(
                                  value: appFontSize,
                                  min: 14,
                                  max: 32,
                                  divisions: 18,
                                  label: appFontSize.toStringAsFixed(0),
                                  onChanged: (value) {
                                    setState(() {
                                      appFontSize = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: appFontSize < 32
                                  ? () {
                                      setState(() {
                                        appFontSize++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),

                      // 10. App icon size
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.appIconSize,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: appIconSize > 16
                                  ? () {
                                      setState(() {
                                        appIconSize--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  overlayShape: SliderComponentShape.noOverlay,
                                  valueIndicatorColor: Colors.transparent,
                                  valueIndicatorTextStyle:
                                      const TextStyle(color: Colors.black),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                    elevation: 0,
                                    pressedElevation: 0,
                                  ),
                                  trackHeight: 2,
                                  activeTrackColor: Colors.black,
                                  inactiveTrackColor: Colors.grey,
                                  thumbColor: Colors.black,
                                  overlayColor: Colors.transparent,
                                ),
                                child: Slider(
                                  value: appIconSize,
                                  min: 16,
                                  max: 128,
                                  divisions: 112,
                                  label: appIconSize.toStringAsFixed(0),
                                  onChanged: (value) {
                                    setState(() {
                                      appIconSize = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: appIconSize < 128
                                  ? () {
                                      setState(() {
                                        appIconSize++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),

                      // 11. App list
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.appList,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!.appsSelected(
                            selectedApps.length,
                            numApps,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _selectApps,
                      ),

                      // 12. Reorder apps
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.reorderApps,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: selectedApps.isEmpty ? null : _reorderApps,
                      ),

                      // 13. Manage folders
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.manageFolders,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(AppLocalizations.of(context)!.createAndOrganizeFolders),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  FolderManagementScreen(
                                prefs: widget.prefs,
                                selectedApps: selectedApps,
                              ),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                      ),

                      // 14. Gestures
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.gestures,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(AppLocalizations.of(context)!.configureGestures),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation,
                                      secondaryAnimation) =>
                                  GestureSettingsScreen(prefs: widget.prefs),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (errorMessage != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.black),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () {
                              setState(() {
                                errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
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

class ReorderAppsScreen extends StatefulWidget {
  final List<String> selectedApps;

  const ReorderAppsScreen({super.key, required this.selectedApps});

  @override
  State<ReorderAppsScreen> createState() => _ReorderAppsScreenState();
}

class _ReorderAppsScreenState extends State<ReorderAppsScreen> {
  late List<String> apps;
  List<AppInfo> appInfos = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    apps = List.from(widget.selectedApps);
    _loadAppInfos();
  }

  Future<void> _loadAppInfos() async {
    try {
      setState(() {
        errorMessage = null;
      });

      final futures = apps.map((packageName) =>
          InstalledApps.getAppInfo(packageName, null)
              .then((app) => AppInfo.fromInstalledApps(app)));

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          appInfos = results;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading app information: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading app information';
          isLoading = false;
        });
      }
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
            title: const Text('Reorder apps'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  // Update selected apps list with new order
                  widget.selectedApps.clear();
                  widget.selectedApps.addAll(apps);
                });
                Navigator.pop(context);
              },
            ),
          ),
          body: Stack(
            children: [
              if (errorMessage != null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAppInfos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reattempt'),
                      ),
                    ],
                  ),
                )
              else
                ScrollConfiguration(
                  behavior: NoGlowScrollBehavior(),
                  child: ReorderableListView(
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.white,
                        child: child,
                      );
                    },
                    buildDefaultDragHandles: false,
                    children: appInfos.map((app) {
                      return ListTile(
                        key: ValueKey(app.packageName),
                        leading: ReorderableDragStartListener(
                          index: appInfos.indexOf(app),
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Text(
                          app.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = apps.removeAt(oldIndex);
                        final appInfo = appInfos.removeAt(oldIndex);
                        apps.insert(newIndex, item);
                        appInfos.insert(newIndex, appInfo);
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
