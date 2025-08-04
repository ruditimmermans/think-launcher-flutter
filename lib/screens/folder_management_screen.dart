import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/folder.dart';
import '../models/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

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
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    final futures = widget.selectedApps.map((packageName) async {
      try {
        final app = await InstalledApps.getAppInfo(packageName, null);
        return AppInfo.fromInstalledApps(app);
      } catch (e) {
        debugPrint('Error loading app info: $e');
        return null;
      }
    });

    final apps = await Future.wait(futures);
    if (mounted) {
      setState(() {
        _appInfoCache = {
          for (var app in apps.whereType<AppInfo>())
            app.packageName: app
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

  void _createFolder() {
    _folderNameController.clear(); // Clear the text field before showing dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: _folderNameController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _folderNameController.clear(); // Clear text when canceling
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
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
            child: const Text('Create'),
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
        title: const Text('Edit Folder'),
        content: TextField(
          controller: _folderNameController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _folderNameController.clear(); // Clear text when canceling
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
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
          title: Text('Manage Apps in ${folder.name}'),
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
                  f.id != folder.id && f.appPackageNames.contains(packageName)
                );

                return CheckboxListTile(
                  title: Text(app.name),
                  value: isInFolder,
                  enabled: !isInOtherFolder,
                  onChanged: isInOtherFolder ? null : (bool? value) {
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  final index = _folders.indexWhere((f) => f.id == folder.id);
                  if (index != -1) {
                    _folders[index] = folder.copyWith(appPackageNames: selectedApps);
                  }
                });
                _saveFolders();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
            title: const Text('Manage Folders'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _createFolder,
            backgroundColor: Colors.black,
            child: const Icon(Icons.create_new_folder),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(folder.name),
                      subtitle: Text('${folder.appPackageNames.length} apps'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.apps),
                            onPressed: () => _manageApps(folder),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editFolder(folder),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
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