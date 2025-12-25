import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/screens/main_screen.dart';
import 'package:think_launcher/utils/no_grow_scroll_behaviour.dart';

class NuxScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const NuxScreen({super.key, required this.prefs});

  @override
  State<NuxScreen> createState() => _NuxScreenState();
}

class _NuxScreenState extends State<NuxScreen> {
  static const MethodChannel _launcherChannel = MethodChannel(
    'com.jackappsdev.think_minimal_launcher/launcher',
  );
  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _launcherMarkedDone = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    await Future.wait([
      _refreshLocationStatus(),
      _refreshNotificationStatus(),
      _refreshLauncherStatus(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshLocationStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _locationGranted = false);
        }
        return;
      }
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (mounted) {
        setState(() => _locationGranted = granted);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationGranted = false);
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      await Geolocator.requestPermission();
    } catch (_) {
      // ignore
    }
    await _refreshLocationStatus();
  }

  Future<void> _refreshNotificationStatus() async {
    try {
      final bool granted = await NotificationListenerService.isPermissionGranted();
      if (mounted) {
        setState(() => _notificationGranted = granted);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notificationGranted = false);
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await NotificationListenerService.requestPermission();
    } catch (_) {
      // ignore
    }
    await _refreshNotificationStatus();
  }

  Future<void> _openDefaultLauncherSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.HOME_SETTINGS',
      );
      await intent.launch();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _refreshLauncherStatus() async {
    try {
      final bool? isDefault =
          await _launcherChannel.invokeMethod<bool>('isDefaultLauncher');
      if (!mounted) return;
      setState(() {
        _launcherMarkedDone = isDefault == true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _launcherMarkedDone = false;
      });
    }
  }

  Future<void> _onContinue() async {
    await widget.prefs.setBool('nuxCompleted', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return MainScreen(prefs: widget.prefs);
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _buildCheckIcon(bool done) {
    return Icon(
      done ? Icons.check_circle : Icons.radio_button_unchecked,
      color: done ? Colors.green : Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(loc.nuxTitle),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: _isLoading
              ? Center(
                  child: Text(
                    loc.loading,
                    style: const TextStyle(fontSize: 18),
                  ),
                )
              : Theme(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ),
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          loc.nuxDescription,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),

                        // Location permission (optional)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on),
                          title: Text(
                            loc.nuxLocationTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            loc.nuxLocationBody,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: _buildCheckIcon(_locationGranted),
                          onTap: _requestLocationPermission,
                        ),

                        const SizedBox(height: 8),

                        // Notification permission (optional)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.notifications),
                          title: Text(
                            loc.nuxNotificationTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            loc.nuxNotificationBody,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: _buildCheckIcon(_notificationGranted),
                          onTap: _requestNotificationPermission,
                        ),

                        const SizedBox(height: 8),

                        // Default launcher info
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.home),
                          title: Text(
                            loc.nuxLauncherTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            loc.nuxLauncherBody,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: _buildCheckIcon(_launcherMarkedDone),
                          onTap: () async {
                            await _openDefaultLauncherSettings();
                            await _refreshLauncherStatus();
                          },
                        ),

                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed: _onContinue,
                          child: Text(loc.nuxContinue),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
