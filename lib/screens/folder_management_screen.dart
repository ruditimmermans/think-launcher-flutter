import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'dart:convert';
import '../models/folder.dart';
import '../models/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:think_launcher/services/icon_pack_service.dart';

class FolderManagementScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final List<String> selectedApps;

  const FolderManagementScreen({
    super.key,
    required this.prefs,
    required this.selectedApps,
  });

  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  List<Folder> _folders = [];
  final TextEditingController _folderNameController = TextEditingController();
  Map<String, AppInfo> _appInfoCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _loadAppInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshAppInfoWithCustomNames();
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    final futures = widget.selectedApps.map((packageName) async {
      try {
        final app = await InstalledApps.getAppInfo(packageName);
        var appInfo = AppInfo.fromInstalledApps(app);

        // Apply icon pack override if configured
        appInfo = await IconPackService.applyIconPackToApp(appInfo, widget.prefs);

        // Load custom name if exists
        final customNamesJson = widget.prefs.getString(
              'customAppNames',
            ) ??
            '{}';
        final customNames = Map<String, String>.from(
          jsonDecode(customNamesJson),
        );
        final customName = customNames[packageName];

        return customName != null
            ? appInfo.copyWith(customName: customName)
            : appInfo;
      } catch (e) {
        debugPrint('Error loading app info: $e');
        return null;
      }
    });

    final apps = await Future.wait(futures);
    if (mounted) {
      setState(() {
        _appInfoCache = {
          for (var app in apps.whereType<AppInfo>()) app.packageName: app
        };
        _isLoading = false;
      });
    }
  }

  void _loadFolders() {
    final foldersJson = widget.prefs.getString('folders');
    if (foldersJson != null) {
      final List<dynamic> decoded = jsonDecode(foldersJson);
      setState(() {
        _folders = decoded.map((f) => Folder.fromJson(f)).toList();
      });
    }
  }

  Future<void> _saveFolders() async {
    final encoded = jsonEncode(_folders.map((f) => f.toJson()).toList());
    await widget.prefs.setString('folders', encoded);
  }

  /// Refreshes app info with updated custom names
  void _refreshAppInfoWithCustomNames() {
    // Load custom names for all apps
    final customNamesJson = widget.prefs.getString('customAppNames') ?? '{}';
    final customNames = Map<String, String>.from(jsonDecode(customNamesJson));

    for (final packageName in _appInfoCache.keys) {
      final app = _appInfoCache[packageName]!;
      final customName = customNames[packageName];
      if (customName != null) {
        _appInfoCache[packageName] = app.copyWith(customName: customName);
      } else {
        _appInfoCache[packageName] = app.copyWith(customName: null);
      }
    }

    setState(() {});
  }

  void _createFolder() {
    _folderNameController.clear(); // Clear the text field before showing dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.createFolder,
          style: const TextStyle(fontSize: 20),
        ),
        content: TextField(
          controller: _folderNameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.folderName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _folderNameController.clear(); // Clear text when canceling
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (_folderNameController.text.trim().isNotEmpty) {
                setState(() {
                  _folders.add(Folder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _folderNameController.text.trim(),
                    appPackageNames: [],
                  ));
                });
                _saveFolders();
                _folderNameController.clear();
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.createFolder),
          ),
        ],
      ),
    );
  }

  void _editFolder(Folder folder) {
    _folderNameController.text = folder.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.editFolder,
          style: const TextStyle(fontSize: 20),
        ),
        content: TextField(
          controller: _folderNameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.folderName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _folderNameController.clear(); // Clear text when canceling
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (_folderNameController.text.trim().isNotEmpty) {
                setState(() {
                  final index = _folders.indexWhere((f) => f.id == folder.id);
                  if (index != -1) {
                    _folders[index] = folder.copyWith(
                      name: _folderNameController.text.trim(),
                    );
                  }
                });
                _saveFolders();
                _folderNameController.clear();
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(Folder folder) {
    ThemeData theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteFolder,
          style: const TextStyle(fontSize: 20),
        ),
        content: Text(
            AppLocalizations.of(context)!.deleteFolderConfirm(folder.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _folders.removeWhere((f) => f.id == folder.id);
              });
              _saveFolders();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _manageApps(Folder folder) {
    // Create a local copy of the folder's apps for the dialog
    List<String> selectedApps = List.from(folder.appPackageNames);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.manageAppsInFolder(folder.name),
            style: const TextStyle(fontSize: 20),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.4,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.selectedApps.length,
              itemBuilder: (context, index) {
                final packageName = widget.selectedApps[index];
                final app = _appInfoCache[packageName];
                if (app == null) return const SizedBox();

                final isInFolder = selectedApps.contains(packageName);
                final isInOtherFolder = _folders.any((f) =>
                    f.id != folder.id &&
                    f.appPackageNames.contains(packageName));

                // Use custom app name if available
                String displayName = app.customName?.isNotEmpty == true
                    ? app.customName!
                    : app.name;

                return CheckboxListTile(
                  title: Text(displayName),
                  value: isInFolder,
                  enabled: !isInOtherFolder,
                  onChanged: isInOtherFolder
                      ? null
                      : (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedApps.add(packageName);
                            } else {
                              selectedApps.remove(packageName);
                            }
                          });
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  final index = _folders.indexWhere((f) => f.id == folder.id);
                  if (index != -1) {
                    _folders[index] =
                        folder.copyWith(appPackageNames: selectedApps);
                  }
                });
                _saveFolders();
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.manageFolders),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _createFolder,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.create_new_folder, color: theme.colorScheme.onPrimary),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.onSurface))
              : _folders.isEmpty
                  ? Center(
                      child: Text(AppLocalizations.of(context)!.noFolders, style: TextStyle(color: theme.colorScheme.onSurface)),
                    )
                  : ListView.builder(
                      itemCount: _folders.length,
                      itemBuilder: (context, index) {
                        final folder = _folders[index];
                        return ListTile(
                          leading: Icon(Icons.folder, color: theme.colorScheme.onSurface.withAlpha(200)),
                          title: Text(folder.name),
                          subtitle: Text(
                            AppLocalizations.of(context)!
                                .appsInFolder(folder.appPackageNames.length),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.apps, color: theme.colorScheme.onSurface),
                                onPressed: () => _manageApps(folder),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: theme.colorScheme.onSurface),
                                onPressed: () => _editFolder(folder),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: theme.colorScheme.onSurface),
                                onPressed: () => _deleteFolder(folder),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
