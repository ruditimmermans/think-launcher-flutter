import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/utils/no_grow_scroll_behaviour.dart';

// Theme and style constants
const _kFontSize = 18.0;
const _kSubtitleFontSize = 12.0;

class GestureSettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const GestureSettingsScreen({super.key, required this.prefs});

  @override
  State<GestureSettingsScreen> createState() => _GestureSettingsScreenState();
}

class _GestureSettingsScreenState extends State<GestureSettingsScreen> {
  bool _autoFocusSearch = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _autoFocusSearch = widget.prefs.getBool('autoFocusSearch') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    await widget.prefs.setBool('autoFocusSearch', _autoFocusSearch);
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
            title: Text(AppLocalizations.of(context)!.gesturesTitle),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Theme(
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
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)!.autoFocusSearch,
                      style: TextStyle(
                        fontSize: _kFontSize,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.autoFocusSearchDescription,
                      style: TextStyle(fontSize: _kSubtitleFontSize, color: theme.colorScheme.onSurface),
                    ),
                    value: _autoFocusSearch,
                    onChanged: (value) {
                      setState(() {
                        _autoFocusSearch = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
