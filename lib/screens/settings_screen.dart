import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import '../models/app_info.dart';
import 'app_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int numApps = 5;
  int numColumns = 1;
  bool showDateTime = true;
  bool showSearchButton = true;
  bool showSettingsButton = true;
  bool useBoldFont = false;
  double appFontSize = 18.0;
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
      numColumns = widget.prefs.getInt('numColumns') ?? 1;
      showDateTime = widget.prefs.getBool('showDateTime') ?? true;
      showSearchButton = widget.prefs.getBool('showSearchButton') ?? true;
      showSettingsButton = widget.prefs.getBool('showSettingsButton') ?? true;
      useBoldFont = widget.prefs.getBool('useBoldFont') ?? false;
      appFontSize = widget.prefs.getDouble('appFontSize') ?? 18.0;
      enableScroll = widget.prefs.getBool('enableScroll') ?? true;
      showIcons = widget.prefs.getBool('showIcons') ?? false;
      selectedApps = widget.prefs.getStringList('selectedApps') ?? [];
    });
  }

  Future<void> _saveSettings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Validar que no haya más apps seleccionadas que el número máximo
      if (selectedApps.length > numApps) {
        selectedApps = selectedApps.sublist(0, numApps);
      }

      await widget.prefs.setInt('numApps', numApps);
      await widget.prefs.setInt('numColumns', numColumns);
      await widget.prefs.setBool('showDateTime', showDateTime);
      await widget.prefs.setBool('showSearchButton', showSearchButton);
      await widget.prefs.setBool('showSettingsButton', showSettingsButton);
      await widget.prefs.setBool('useBoldFont', useBoldFont);
      await widget.prefs.setDouble('appFontSize', appFontSize);
      await widget.prefs.setBool('enableScroll', enableScroll);
      await widget.prefs.setBool('showIcons', showIcons);
      await widget.prefs.setStringList('selectedApps', selectedApps);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error al guardar configuración: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error saving settings';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            FilledButton.tonal(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // 1. Number of apps
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Number of apps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Slider(
                value: numApps.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                label: numApps.toString(),
                onChanged: (value) {
                  setState(() {
                    numApps = value.toInt();
                    if (selectedApps.length > numApps) {
                      selectedApps = selectedApps.sublist(0, numApps);
                    }
                  });
                },
              ),

              // 2. Number of columns
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Number of columns',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Slider(
                value: numColumns.toDouble(),
                min: 1,
                max: 3,
                divisions: 2,
                label: numColumns.toString(),
                onChanged: (value) {
                  setState(() {
                    numColumns = value.toInt();
                  });
                },
              ),

              // 3. Show date, time and battery
              SwitchListTile(
                title: const Text(
                  'Show date, time and battery',
                  style: TextStyle(
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

              // 4. Show search button
              SwitchListTile(
                title: const Text(
                  'Show search button',
                  style: TextStyle(
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

              // 5. Show settings button
              SwitchListTile(
                title: const Text(
                  'Show settings button',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: showSettingsButton,
                onChanged: (value) {
                  setState(() {
                    showSettingsButton = value;
                  });
                },
              ),

              // 6. Use bold font
              SwitchListTile(
                title: const Text(
                  'Use bold font',
                  style: TextStyle(
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

              // 7. Enable list scrolling
              SwitchListTile(
                title: const Text(
                  'Enable list scrolling',
                  style: TextStyle(
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

              // 8. Show icons
              SwitchListTile(
                title: const Text(
                  'Show icons',
                  style: TextStyle(
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

              // 9. App font size
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'App font size',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Slider(
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

              // 10. App list
              ListTile(
                title: const Text(
                  'App list',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle:
                    Text('${selectedApps.length} of $numApps apps selected'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectApps,
              ),

              // 11. Reorder apps
              ListTile(
                title: const Text(
                  'Reorder apps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: selectedApps.isEmpty ? null : _reorderApps,
              ),
            ],
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
      debugPrint('Error al cargar información de apps: $e');
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reorder apps'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, apps),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
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
            ReorderableListView(
              children: appInfos.map((app) {
                return ListTile(
                  key: ValueKey(app.packageName),
                  leading: const Icon(Icons.drag_handle),
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
        ],
      ),
    );
  }
}
