import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_info.dart';

class SearchScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SearchScreen({
    super.key,
    required this.prefs,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<AppInfo> apps = [];
  List<AppInfo> filteredApps = [];
  final TextEditingController _searchController = TextEditingController();
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    try {
      final installedApps =
          await InstalledApps.getInstalledApps(true, false, '');
      if (mounted) {
        setState(() {
          apps = installedApps
              .map((app) => AppInfo.fromInstalledApps(app))
              .toList();
          filteredApps = List.from(apps);
        });
      }
    } catch (e) {
      debugPrint('Error loading apps: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading applications';
        });
      }
    }
  }

  void _filterApps(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredApps = List.from(apps);
      } else {
        filteredApps = apps
            .where(
                (app) => app.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _launchApp(String packageName) async {
    try {
      await InstalledApps.startApp(packageName);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error opening app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the application'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search apps'),
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              onChanged: _filterApps,
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.black),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredApps.length,
                itemBuilder: (context, index) {
                  final app = filteredApps[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _launchApp(app.packageName),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
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
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
