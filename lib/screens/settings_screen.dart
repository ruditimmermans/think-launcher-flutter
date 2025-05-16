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
          errorMessage = 'Error al guardar la configuración';
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
        title: const Text('Configuración'),
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
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // 1. Número de apps
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Número de apps',
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
                    // Ajustar la lista de apps si es necesario
                    if (selectedApps.length > numApps) {
                      selectedApps = selectedApps.sublist(0, numApps);
                    }
                  });
                },
              ),

              // 2. Número de columnas
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Número de columnas',
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

              // 3. Mostrar fecha, hora y batería
              SwitchListTile(
                title: const Text(
                  'Mostrar fecha, hora y batería',
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

              // 4. Mostrar botón de búsqueda
              SwitchListTile(
                title: const Text(
                  'Mostrar botón de búsqueda',
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

              // 5. Mostrar botón de configuración
              SwitchListTile(
                title: const Text(
                  'Mostrar botón de configuración',
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

              // 6. Usar fuente en negrita
              SwitchListTile(
                title: const Text(
                  'Usar fuente en negrita',
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

              // 7. Permitir scroll en la lista
              SwitchListTile(
                title: const Text(
                  'Permitir scroll en la lista',
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

              // 8. Mostrar iconos
              SwitchListTile(
                title: const Text(
                  'Mostrar iconos',
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

              // 9. Tamaño de fuente de las apps
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tamaño de fuente de las apps',
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

              // 10. Lista de apps
              ListTile(
                title: const Text(
                  'Lista de apps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                    '${selectedApps.length} de $numApps apps seleccionadas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectApps,
              ),

              // 11. Reordenar apps
              ListTile(
                title: const Text(
                  'Reordenar apps',
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
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
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
          errorMessage = 'Error al cargar la información de las apps';
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
        title: const Text('Reordenar apps'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, apps),
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                    child: const Text('Reintentar'),
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
