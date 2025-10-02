import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/utils/no_grow_scroll_behaviour.dart';
import 'package:think_launcher/screens/app_selection_screen.dart';
import 'package:think_launcher/screens/folder_management_screen.dart';
import 'package:think_launcher/screens/gesture_settings_screen.dart';
import 'package:think_launcher/screens/reorder_apps_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool showDateTime = true;
  bool showSearchButton = true;
  double appFontSize = 18.0;
  double appIconSize = 35.0;
  bool enableScroll = true;
  bool showIcons = false;
  bool showFolderChevron = true;
  bool colorMode = true;
  bool wakeOnNotification = false;
  bool scrollToTop = false;
  List<String> selectedApps = [];
  bool isLoading = false;
  String? errorMessage;
  String? wallpaperPath;
  double wallpaperBlur = 0.0; // 0 = no blur when no wallpaper; 1-10 when set

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      showDateTime = widget.prefs.getBool('showDateTime') ?? true;
      showSearchButton = widget.prefs.getBool('showSearchButton') ?? true;
      appFontSize = widget.prefs.getDouble('appFontSize') ?? 18.0;
      appIconSize = widget.prefs.getDouble('appIconSize') ?? 35.0;
      enableScroll = widget.prefs.getBool('enableScroll') ?? true;
      showIcons = widget.prefs.getBool('showIcons') ?? true;
      showFolderChevron = widget.prefs.getBool('showFolderChevron') ?? true;
      colorMode = widget.prefs.getBool('colorMode') ?? true;
      wakeOnNotification = widget.prefs.getBool('wakeOnNotification') ?? false;
      scrollToTop = widget.prefs.getBool('scrollToTop') ?? false;
      selectedApps = widget.prefs.getStringList('selectedApps') ?? [];
      wallpaperPath = widget.prefs.getString('wallpaperPath');
      wallpaperBlur = wallpaperPath == null
          ? 0.0
          : (widget.prefs.getDouble('wallpaperBlur') ?? 3.0);
      if (wallpaperPath != null && wallpaperBlur < 1.0) {
        wallpaperBlur = 1.0;
      }
    });
  }

  Future<void> _saveSettings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await widget.prefs.setBool('showDateTime', showDateTime);
      await widget.prefs.setBool('showSearchButton', showSearchButton);
      await widget.prefs.setDouble('appFontSize', appFontSize);
      await widget.prefs.setDouble('appIconSize', appIconSize);
      await widget.prefs.setBool('enableScroll', enableScroll);
      await widget.prefs.setBool('showIcons', showIcons);
      await widget.prefs.setBool('showFolderChevron', showFolderChevron);
      await widget.prefs.setBool('colorMode', colorMode);
      await widget.prefs.setBool('wakeOnNotification', wakeOnNotification);
      await widget.prefs.setBool('scrollToTop', scrollToTop);
      await widget.prefs.setStringList('selectedApps', selectedApps);
      if (wallpaperPath == null) {
        await widget.prefs.remove('wallpaperPath');
      } else {
        await widget.prefs.setString('wallpaperPath', wallpaperPath!);
      }
      await widget.prefs.setDouble('wallpaperBlur', wallpaperBlur);

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
        pageBuilder: (context, animation, secondaryAnimation) {
          return AppSelectionScreen(
            prefs: widget.prefs,
            selectedApps: List.from(selectedApps),
          );
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        selectedApps = List.from(result);
      });
      await _saveSettings();
    }
  }

  Future<void> _reorderApps() async {
    if (selectedApps.isEmpty) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ReorderAppsScreen(prefs: widget.prefs, folder: null);
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        selectedApps = result;
        _saveSettings();
      });
    }
  }

  Future<void> _exportSettings() async {
    try {
      final prefs = widget.prefs;
      final Map<String, dynamic> data = {
        'showDateTime': prefs.getBool('showDateTime') ?? true,
        'showSearchButton': prefs.getBool('showSearchButton') ?? true,
        'enableScroll': prefs.getBool('enableScroll') ?? true,
        'showIcons': prefs.getBool('showIcons') ?? true,
        'colorMode': prefs.getBool('colorMode') ?? true,
        'wakeOnNotification': prefs.getBool('wakeOnNotification') ?? false,
        'scrollToTop': prefs.getBool('scrollToTop') ?? false,
        'appFontSize': prefs.getDouble('appFontSize') ?? 18.0,
        'appIconSize': prefs.getDouble('appIconSize') ?? 35.0,
        'selectedApps': prefs.getStringList('selectedApps') ?? <String>[],
        'showStatusBar': prefs.getBool('showStatusBar') ?? false,
        'showFolderChevron': prefs.getBool('showFolderChevron') ?? true,
        'wallpaperBlur': prefs.getDouble('wallpaperBlur') ?? 0.0,
      };

      final String jsonText = const JsonEncoder.withIndent('  ').convert(data);

      String? savePath;
      try {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context)!.exportSettings,
          fileName: 'think_launcher_settings.json',
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
      } catch (_) {
        savePath = null;
      }

      if (savePath == null) {
        // Try saving to public Downloads directory first (Android only)
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          final fallback =
              '${downloadsDir.path}/think_launcher_settings_${DateTime.now().millisecondsSinceEpoch}.json';
          await File(fallback).writeAsString(jsonText);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .exportSavedToDownloads(Uri.file(fallback).pathSegments.last),
            ),
          ));
          return;
        } catch (_) {
          // Fallback to app-specific external storage if Downloads isn't writable
          final dir = await getExternalStorageDirectory();
          final fallback =
              '${dir?.path}/think_launcher_settings_${DateTime.now().millisecondsSinceEpoch}.json';
          await File(fallback).writeAsString(jsonText);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .exportFallbackSaved(Uri.file(fallback).pathSegments.last),
            ),
          ));
          return;
        }
      }

      await File(savePath).writeAsString(jsonText);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.exportSuccess),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = AppLocalizations.of(context)!.exportFailed;
      });
    }
  }

  Future<void> _importSettings() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final String? path = result.files.single.path;
      if (path == null) {
        setState(() {
          errorMessage = AppLocalizations.of(context)!.invalidFileSelection;
        });
        return;
      }

      final String content = await File(path).readAsString();
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(content);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Root is not an object');
        }
        data = decoded;
      } catch (_) {
        setState(() {
          errorMessage = AppLocalizations.of(context)!.invalidJsonFile;
        });
        return;
      }

      // Helper getters with type safety and descriptive names
      bool? getBoolOrNull(String key) {
        return data[key] is bool ? data[key] as bool : null;
      }

      double? getDoubleOrNull(String key) {
        return data[key] is num ? data[key].toDouble() : null;
      }

      List<String>? getStringListOrNull(String key) {
        final value = data[key];
        if (value is List) {
          final list = value.whereType<String>().toList();
          return list.length == value.length ? list : null;
        }
        return null;
      }

      final prefs = widget.prefs;

      // Apply known keys only
      final bool? vShowDateTime = getBoolOrNull('showDateTime');
      if (vShowDateTime != null) {
        await prefs.setBool('showDateTime', vShowDateTime);
      }

      final bool? vShowSearchButton = getBoolOrNull('showSearchButton');
      if (vShowSearchButton != null) {
        await prefs.setBool('showSearchButton', vShowSearchButton);
      }

      final bool? vEnableScroll = getBoolOrNull('enableScroll');
      if (vEnableScroll != null) {
        await prefs.setBool('enableScroll', vEnableScroll);
      }

      final bool? vShowIcons = getBoolOrNull('showIcons');
      if (vShowIcons != null) {
        await prefs.setBool('showIcons', vShowIcons);
      }

      final bool? vColorMode = getBoolOrNull('colorMode');
      if (vColorMode != null) {
        await prefs.setBool('colorMode', vColorMode);
      }

      final bool? vShowFolderChevron = getBoolOrNull('showFolderChevron');
      if (vShowFolderChevron != null) {
        await prefs.setBool('showFolderChevron', vShowFolderChevron);
      }

      final bool? vWakeOnNotification = getBoolOrNull('wakeOnNotification');
      if (vWakeOnNotification != null) {
        await prefs.setBool('wakeOnNotification', vWakeOnNotification);
      }

      final bool? vScrollToTop = getBoolOrNull('scrollToTop');
      if (vScrollToTop != null) {
        await prefs.setBool('scrollToTop', vScrollToTop);
      }

      final double? vAppFontSize = getDoubleOrNull('appFontSize');
      if (vAppFontSize != null) {
        await prefs.setDouble('appFontSize', vAppFontSize);
      }

      final double? vAppIconSize = getDoubleOrNull('appIconSize');
      if (vAppIconSize != null) {
        await prefs.setDouble('appIconSize', vAppIconSize);
      }

      final List<String>? vSelectedApps = getStringListOrNull('selectedApps');
      if (vSelectedApps != null) {
        await prefs.setStringList('selectedApps', vSelectedApps);
      }

      final bool? vShowStatusBar = getBoolOrNull('showStatusBar');
      if (vShowStatusBar != null) {
        await prefs.setBool('showStatusBar', vShowStatusBar);
      }

      final double? vWallpaperBlur = getDoubleOrNull('wallpaperBlur');
      if (vWallpaperBlur != null) {
        await prefs.setDouble('wallpaperBlur', vWallpaperBlur);
      }

      // Refresh UI and system UI overlays
      if (!mounted) return;
      _loadSettings();
      final showStatusBar = prefs.getBool('showStatusBar') ?? false;
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: showStatusBar
            ? [SystemUiOverlay.top, SystemUiOverlay.bottom]
            : [SystemUiOverlay.bottom],
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.importSuccess),
      ));
    } catch (e) {
      debugPrint('Error importing settings: $e');
      if (!mounted) return;
      setState(() {
        errorMessage = AppLocalizations.of(context)!.importFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.settingsTitle),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
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
                          AppLocalizations.of(context)!.showInformationPanel,
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
                          _saveSettings();
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
                          _saveSettings();
                        },
                      ),

                      // 3. Enable list scrolling
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
                          _saveSettings();
                        },
                      ),

                      // 4. Show status bar
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
                          _saveSettings();
                        },
                      ),

                      // 5. Color mode
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.colorMode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: colorMode,
                        onChanged: (value) {
                          setState(() {
                            colorMode = value;
                          });
                          _saveSettings();
                        },
                      ),

                      // 6. Show icons
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
                          _saveSettings();
                        },
                      ),

                      // 7. Wake on notification
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.wakeOnNotification,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: wakeOnNotification,
                        onChanged: (value) {
                          setState(() {
                            wakeOnNotification = value;
                          });
                          _saveSettings();
                        },
                      ),

                      // 7b. Scroll to top on folder close
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.scrollToTop,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: scrollToTop,
                        onChanged: (value) {
                          setState(() {
                            scrollToTop = value;
                          });
                          _saveSettings();
                        },
                      ),

                      // 8. Show folder chevron
                      SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.showFolderChevron,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: showFolderChevron,
                        onChanged: (value) {
                          setState(() {
                            showFolderChevron = value;
                          });
                          _saveSettings();
                        },
                      ),

                      // 9. Wallpaper (single setting item)
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.wallpaper,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          wallpaperPath == null
                              ? AppLocalizations.of(context)!.noWallpaperSet
                              : Uri.file(wallpaperPath!).pathSegments.isNotEmpty
                                  ? Uri.file(wallpaperPath!).pathSegments.last
                                  : wallpaperPath!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        trailing: wallpaperPath == null
                            ? const Icon(Icons.chevron_right)
                            : IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  setState(() {
                                    wallpaperPath = null;
                                    wallpaperBlur = 0.0;
                                  });
                                  await _saveSettings();
                                },
                              ),
                        onTap: () async {
                          final picker = ImagePicker();
                          final XFile? picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            requestFullMetadata: false,
                          );
                          if (picked != null) {
                            try {
                              final appDir =
                                  await getApplicationDocumentsDirectory();
                              final wallpapersDir =
                                  Directory('${appDir.path}/wallpapers');
                              if (!await wallpapersDir.exists()) {
                                await wallpapersDir.create(recursive: true);
                              }

                              final String filename =
                                  Uri.file(picked.path).pathSegments.last;
                              final String destPath =
                                  '${wallpapersDir.path}/$filename';

                              final savedFile =
                                  await File(picked.path).copy(destPath);

                              setState(() {
                                wallpaperPath = savedFile.path;
                                if (wallpaperBlur == 0.0) {
                                  wallpaperBlur = 3.0;
                                }
                              });
                              await _saveSettings();
                            } catch (e) {
                              setState(() {
                                wallpaperPath = picked.path;
                                if (wallpaperBlur == 0.0) {
                                  wallpaperBlur = 3.0;
                                }
                              });
                              await _saveSettings();
                            }
                          }
                        },
                      ),

                      // 9b. Wallpaper blur slider (only when wallpaper is set)
                      if (wallpaperPath != null) ...[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                          child: Text(
                            AppLocalizations.of(context)!.wallpaperBlur,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: wallpaperBlur > 1.0
                                        ? () {
                                            setState(() {
                                              wallpaperBlur =
                                                  (wallpaperBlur - 1)
                                                      .clamp(1.0, 10.0);
                                            });
                                            _saveSettings();
                                          }
                                        : null,
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        overlayShape:
                                            SliderComponentShape.noOverlay,
                                        valueIndicatorColor: Colors.transparent,
                                        valueIndicatorTextStyle:
                                            const TextStyle(
                                          color: Colors.black,
                                        ),
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
                                        showValueIndicator: ShowValueIndicator
                                            .always,
                                      ),
                                      child: Slider(
                                        value: wallpaperBlur,
                                        min: 1,
                                        max: 10,
                                        divisions: 9,
                                        label: wallpaperBlur.toStringAsFixed(0),
                                        onChanged: (value) {
                                          setState(() {
                                            wallpaperBlur = value;
                                          });
                                          _saveSettings();
                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: wallpaperBlur < 10.0
                                        ? () {
                                            setState(() {
                                              wallpaperBlur =
                                                  (wallpaperBlur + 1)
                                                      .clamp(1.0, 10.0);
                                            });
                                            _saveSettings();
                                          }
                                        : null,
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 10. App font size
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
                                  showValueIndicator:
                                      ShowValueIndicator.onlyForContinuous,
                                ),
                                child: Slider(
                                  value: appFontSize,
                                  min: 14,
                                  max: 32,
                                  label: appFontSize.toStringAsFixed(0),
                                  onChanged: (value) {
                                    setState(() {
                                      appFontSize = value.roundToDouble();
                                    });
                                    _saveSettings();
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

                      // 11. App icon size
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
                                  showValueIndicator:
                                      ShowValueIndicator.onlyForContinuous,
                                ),
                                child: Slider(
                                  value: appIconSize,
                                  min: 16,
                                  max: 128,
                                  label: appIconSize.toStringAsFixed(0),
                                  onChanged: (value) {
                                    setState(() {
                                      appIconSize = value.roundToDouble();
                                    });
                                    _saveSettings();
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

                      // 12. App list
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.appList,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!
                              .selectedAppsCount(selectedApps.length),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _selectApps,
                      ),

                      // 13. Reorder apps
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.reorderAppsFolders,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: selectedApps.isEmpty ? null : _reorderApps,
                      ),

                      // 14. Manage folders
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.manageFolders,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(AppLocalizations.of(context)!
                            .createAndOrganizeFolders),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
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

                      // 15. Gestures
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.gestures,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                            AppLocalizations.of(context)!.configureGestures),
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

                      // 16. Export settings
                      const Divider(height: 32),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.exportSettings,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!
                              .exportSettingsSubtitle,
                        ),
                        onTap: _exportSettings,
                      ),

                      // 16. Import settings
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.importSettings,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!
                              .importSettingsSubtitle,
                        ),
                        onTap: _importSettings,
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
