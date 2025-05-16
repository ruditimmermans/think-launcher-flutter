import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
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
  Timer? _timer;
  bool _isNavigating = false;
  final Battery _battery = Battery();
  bool _isFirstLoad = true;

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
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateDateTime();
      _updateBattery();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Solo actualizamos la batería y la fecha/hora
      _updateBattery();
      _updateDateTime();

      // Si es la primera carga, cargamos la configuración
      if (_isFirstLoad) {
        _loadSettings();
        _isFirstLoad = false;
      }
    }
  }

  Future<AppInfo> _getAppInfo(String packageName) async {
    // Si ya tenemos la información en caché, la devolvemos
    if (appInfoCache.containsKey(packageName)) {
      return appInfoCache[packageName]!;
    }

    try {
      final app = await InstalledApps.getAppInfo(packageName, null);
      final appInfo = AppInfo.fromInstalledApps(app);
      appInfoCache[packageName] = appInfo;
      return appInfo;
    } catch (e) {
      debugPrint('Error al obtener información de la app $packageName: $e');
      // Si hay error, intentamos obtener la información básica
      try {
        final app = await InstalledApps.getAppInfo(packageName, null);
        return AppInfo.fromInstalledApps(app);
      } catch (e) {
        // Si aún hay error, devolvemos un AppInfo básico
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
  }

  // Precargar la información de todas las apps seleccionadas
  Future<void> _preloadAppInfo() async {
    for (final packageName in selectedApps) {
      if (!appInfoCache.containsKey(packageName)) {
        await _getAppInfo(packageName);
      }
    }
  }

  void _loadSettings() {
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
      selectedApps = widget.prefs.getStringList('selectedApps') ?? [];

      // Precargar la información de las apps
      _preloadAppInfo();
    });
  }

  void _updateDateTime() {
    if (!mounted || !showDateTime) return;
    final now = DateTime.now();
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd - MMMM - yyyy');
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
      debugPrint('Error al obtener nivel de batería: $e');
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
      debugPrint('Error al abrir configuración: $e');
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
      debugPrint('Error al abrir búsqueda: $e');
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error al cargar las apps: ${snapshot.error}');
          return Center(
            child: Text(
              'Error al cargar las aplicaciones',
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
              'No hay aplicaciones seleccionadas',
              style: TextStyle(
                fontSize: appFontSize,
                fontWeight: useBoldFont ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }

        return ReorderableGridView.count(
          crossAxisCount: numColumns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
          children: apps.map((app) => _buildAppTile(app)).toList(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final app = selectedApps.removeAt(oldIndex);
              selectedApps.insert(newIndex, app);
              widget.prefs.setStringList('selectedApps', selectedApps);
            });
          },
        );
      },
    );
  }

  Widget _buildAppTile(AppInfo app) {
    return Card(
      key: ValueKey(app.packageName),
      child: InkWell(
        onTap: () => InstalledApps.startApp(app.packageName),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showIcons && app.icon != null)
                Image.memory(
                  app.icon!,
                  width: 48,
                  height: 48,
                ),
              if (showIcons && app.icon != null) const SizedBox(height: 8),
              Text(
                app.name,
                style: TextStyle(
                  fontSize: appFontSize,
                  fontWeight: useBoldFont ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
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
              SafeArea(
                child: Column(
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
                                'Presiona el botón de configuración para comenzar',
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.7,
                                ),
                                child: enableScroll
                                    ? _buildAppGrid()
                                    : LayoutBuilder(
                                        builder: (context, constraints) {
                                          // Calculamos el número de filas necesarias
                                          final numRows =
                                              (selectedApps.length / numColumns)
                                                  .ceil();
                                          // Calculamos la altura disponible por fila
                                          final availableHeight =
                                              constraints.maxHeight / numRows;
                                          // Calculamos el aspect ratio basado en la altura disponible
                                          final aspectRatio =
                                              (constraints.maxWidth /
                                                      numColumns) /
                                                  availableHeight;

                                          return GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: numColumns,
                                              childAspectRatio: aspectRatio,
                                              mainAxisSpacing: 1,
                                              crossAxisSpacing: 1,
                                            ),
                                            itemCount: selectedApps.length,
                                            itemBuilder: (context, index) {
                                              return FutureBuilder<AppInfo>(
                                                future: _getAppInfo(
                                                    selectedApps[index]),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData) {
                                                    return const SizedBox();
                                                  }
                                                  final app = snapshot.data!;
                                                  return Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () => InstalledApps
                                                          .startApp(
                                                              app.packageName),
                                                      splashColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 16.0,
                                                          vertical: 8.0,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            if (showIcons &&
                                                                app.icon !=
                                                                    null)
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            16.0),
                                                                child: Image
                                                                    .memory(
                                                                  app.icon!,
                                                                  width:
                                                                      appFontSize *
                                                                          1.5,
                                                                  height:
                                                                      appFontSize *
                                                                          1.5,
                                                                ),
                                                              ),
                                                            Expanded(
                                                              child: Text(
                                                                app.name,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      appFontSize,
                                                                  fontWeight: useBoldFont
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .normal,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
