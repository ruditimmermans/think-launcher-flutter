import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:think_launcher/l10n/app_localizations.dart';

/// Simple model for an icon pack entry exposed from the native side.
class IconPackInfo {
  final String packageName;
  final String name;

  IconPackInfo({
    required this.packageName,
    required this.name,
  });

  factory IconPackInfo.fromMap(Map<dynamic, dynamic> map) {
    return IconPackInfo(
      packageName: (map['packageName'] ?? '') as String,
      name: (map['name'] ?? '') as String,
    );
  }
}

class IconPackScreen extends StatefulWidget {
  final String? selectedIconPackPackage;

  const IconPackScreen({
    super.key,
    required this.selectedIconPackPackage,
  });

  @override
  State<IconPackScreen> createState() => _IconPackScreenState();
}

class _IconPackScreenState extends State<IconPackScreen> {
  static const MethodChannel _channel = MethodChannel('com.jackappsdev.think_minimal_launcher/icon_packs');

  List<IconPackInfo> _iconPacks = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIconPacks();
  }

  Future<void> _loadIconPacks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _channel.invokeMethod<List<dynamic>>('getIconPacks');

      final packs = (result ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map(IconPackInfo.fromMap)
          .toList();

      if (!mounted) return;
      setState(() {
        _iconPacks = packs;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message ?? 'Failed to load icon packs.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load icon packs.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectDefault() {
    // Empty packageName indicates "System default" selection
    Navigator.pop<Map<String, String>?>(context, {
      'packageName': '',
      'name': '',
    });
  }

  void _selectPack(IconPackInfo pack) {
    Navigator.pop<Map<String, String>?>(context, {
      'packageName': pack.packageName,
      'name': pack.name,
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedPackage = widget.selectedIconPackPackage;
    ThemeData theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.iconPackScreenTitle),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop<Map<String, String>?>(context, null),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  AppLocalizations.of(context)!.iconPackNote,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    _errorMessage ??
                        AppLocalizations.of(context)!.iconPackErrorLoading,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              if (_isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      // System default option
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.iconPackSystemDefault,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: selectedPackage == null
                            ? Icon(Icons.check, color: theme.colorScheme.onSurface)
                            : null,
                        onTap: _selectDefault,
                      ),
                      const Divider(),
                      // Icon pack options
                      ..._iconPacks.map((pack) {
                        final isSelected = pack.packageName == selectedPackage;
                        return ListTile(
                          title: Text(
                            pack.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            pack.packageName,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check, color: theme.colorScheme.onSurface)
                              : null,
                          onTap: () => _selectPack(pack),
                        );
                      }),
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
