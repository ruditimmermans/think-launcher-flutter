import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/utils/no_grow_scroll_behaviour.dart';
import 'package:think_launcher/models/app_info.dart';

/// Screen for selecting a single app (e.g., for weather icon action).
class SingleAppSelectionScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final String? currentlySelectedPackageName;

  const SingleAppSelectionScreen({
    super.key,
    required this.prefs,
    this.currentlySelectedPackageName,
  });

  @override
  State<SingleAppSelectionScreen> createState() =>
      _SingleAppSelectionScreenState();
}

class _SingleAppSelectionScreenState extends State<SingleAppSelectionScreen> {
  List<AppInfo> apps = [];
  List<AppInfo> filteredApps = [];
  final TextEditingController _searchController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

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
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final installedApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: false,
        packageNamePrefix: '',
      );

      final appInfos =
          installedApps.map((app) => AppInfo.fromInstalledApps(app)).toList();
      appInfos.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          apps = appInfos;
          filteredApps = List.from(appInfos);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading apps: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading applications';
          isLoading = false;
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

  void _selectApp(String packageName) {
    Navigator.pop(context, packageName);
  }

  void _clearSelection() {
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.selectAppTitle),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
              tooltip: AppLocalizations.of(context)!.cancel,
            ),
            actions: [
              if (widget.currentlySelectedPackageName != null)
                TextButton(
                  onPressed: _clearSelection,
                  child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: theme.colorScheme.onSurface)),
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  showCursor: true,
                  cursorColor: theme.colorScheme.onSurface,
                  cursorWidth: 2,
                  cursorRadius: const Radius.circular(1),
                  cursorOpacityAnimates: false,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchAppsHint,
                    prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: _filterApps,
                ),
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                )
              else if (isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.onSurface),
                  ),
                )
              else
                Expanded(
                  child: ScrollConfiguration(
                    behavior: NoGlowScrollBehavior(),
                    child: ListView.builder(
                      itemCount: filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = filteredApps[index];
                        final isSelected =
                            widget.currentlySelectedPackageName ==
                                app.packageName;

                        // Use custom app name if available
                        String displayName = app.customName?.isNotEmpty == true
                            ? app.customName!
                            : app.name;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectApp(app.packageName),
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
                                      displayName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: theme.colorScheme.onSurface,
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

