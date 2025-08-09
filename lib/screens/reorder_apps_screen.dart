import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/models/folder.dart';
import 'package:think_launcher/models/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'dart:convert';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/models/reorderable_item.dart';

class ReorderAppsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final Folder? folder;
  final List<String>? selectedApps;

  const ReorderAppsScreen({
    super.key,
    required this.prefs,
    this.folder,
    this.selectedApps,
  });

  @override
  State<ReorderAppsScreen> createState() => _ReorderAppsScreenState();
}

class _ReorderAppsScreenState extends State<ReorderAppsScreen> {
  late List<ReorderableItem> _items;
  final Map<String, AppInfo> _appInfoCache = {};
  List<Folder> _folders = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _items = [];
    _preloadAppInfo();
  }

  void _loadFolders() {
    final foldersJson = widget.prefs.getString('folders');
    if (foldersJson != null) {
      final List<dynamic> decoded = jsonDecode(foldersJson);
      _folders = decoded.map((f) => Folder.fromJson(f)).toList();
    }
  }

  Future<void> _preloadAppInfo() async {
    final appPackageNames = widget.folder?.appPackageNames ?? widget.selectedApps ?? [];
    
    for (final packageName in appPackageNames) {
      if (!_appInfoCache.containsKey(packageName)) {
        try {
          final app = await InstalledApps.getAppInfo(packageName, null);
          if (mounted) {
            final appInfo = AppInfo.fromInstalledApps(app);
            setState(() {
              _appInfoCache[packageName] = appInfo;
            });
          }
        } catch (e) {
          debugPrint('Error getting app info for $packageName: $e');
        }
      }
    }

    if (widget.folder != null) {
      // If we're in a folder, show only folder's apps
      setState(() {
        _items = appPackageNames
            .where((packageName) => _appInfoCache.containsKey(packageName))
            .map((packageName) => ReorderableItem.fromApp(_appInfoCache[packageName]!))
            .toList();
      });
    } else if (widget.selectedApps != null) {
      // If we're in settings (reorder apps), show all selected apps
      setState(() {
        _items = appPackageNames
            .where((packageName) => _appInfoCache.containsKey(packageName))
            .map((packageName) => ReorderableItem.fromApp(_appInfoCache[packageName]!))
            .toList();
      });
    } else {
      // If we're in the main screen, add both folders and apps
      setState(() {
        _items = [
          ..._folders.map((f) => ReorderableItem.fromFolder(f)),
          ...appPackageNames
              .where((packageName) => _appInfoCache.containsKey(packageName))
              .map((packageName) => ReorderableItem.fromApp(_appInfoCache[packageName]!))
              .where((item) => !_folders.any((f) => f.appPackageNames.contains(item.id)))
        ];
      });
    }
  }

  Future<void> _saveOrder() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });
    if (widget.folder != null) {
      // Save folder app order
      final appPackageNames = _items
          .where((item) => item.type == ReorderableItemType.app)
          .map((item) => item.id)
          .toList();
      
      final updatedFolder = widget.folder!.copyWith(appPackageNames: appPackageNames);
      final folders = (jsonDecode(widget.prefs.getString('folders') ?? '[]') as List)
          .map((f) => Folder.fromJson(f))
          .toList();

      final index = folders.indexWhere((f) => f.id == widget.folder!.id);
      if (index != -1) {
        folders[index] = updatedFolder;
        final foldersJson = jsonEncode(folders.map((f) => f.toJson()).toList());
        widget.prefs.setString('folders', foldersJson);
      }
    } else if (widget.selectedApps != null) {
      // Save reordered apps from settings
      final appPackageNames = _items
          .map((item) => item.id)
          .toList();
      widget.prefs.setStringList('selectedApps', appPackageNames);
    } else {
      // Save main screen order while preserving folder contents
      final currentFolders = (jsonDecode(widget.prefs.getString('folders') ?? '[]') as List)
          .map((f) => Folder.fromJson(f))
          .toList();

      // Create a map of folder ID to its contents
      final folderContents = {
        for (var folder in currentFolders)
          folder.id: folder.appPackageNames
      };

      // Get the new folder order while preserving their contents
      final reorderedFolders = _items
          .where((item) => item.type == ReorderableItemType.folder)
          .map((item) => item.folder!.copyWith(
                appPackageNames: folderContents[item.folder!.id] ?? [],
              ))
          .toList();
      
      // Get unorganized apps
      final appPackageNames = _items
          .where((item) => item.type == ReorderableItemType.app)
          .map((item) => item.id)
          .toList();

      final foldersJson = jsonEncode(reorderedFolders.map((f) => f.toJson()).toList());
      widget.prefs.setString('folders', foldersJson);
      widget.prefs.setStringList('selectedApps', appPackageNames);
    }

    // Add a small delay to show the saving indicator
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder != null 
          ? AppLocalizations.of(context)!.reorderAppsInFolder 
          : AppLocalizations.of(context)!.reorderApps),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            Container(
              padding: const EdgeInsets.all(16),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          
          Widget? leadingIcon;
          if (item.type == ReorderableItemType.folder) {
            leadingIcon = const Icon(Icons.folder, color: Colors.grey);
          } else if (item.appInfo?.icon != null) {
            leadingIcon = ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: Image.memory(
                item.appInfo!.icon!,
                width: 24,
                height: 24,
              ),
            );
          }

          return ListTile(
            key: Key(item.id),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_handle, color: Colors.grey),
                const SizedBox(width: 16),
                if (leadingIcon != null) leadingIcon,
              ],
            ),
            title: Text(item.name),
          );
        },
        onReorder: (oldIndex, newIndex) async {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
          // Auto-save after reordering
          await _saveOrder();
        },
      ),
    );
  }
}