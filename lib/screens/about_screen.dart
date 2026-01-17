import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:think_launcher/l10n/app_localizations.dart';
import 'package:think_launcher/screens/license_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<PackageInfo> _loadPackageInfo() {
    return PackageInfo.fromPlatform();
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
            title: Text(AppLocalizations.of(context)!.aboutTitle),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
          ),
          backgroundColor: theme.colorScheme.surface,
          body: FutureBuilder<PackageInfo>(
            future: _loadPackageInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.aboutLoadError,
                  ),
                );
              }

              final info = snapshot.data!;
              final versionText = info.version;

              return ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.aboutVersionLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(versionText),
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.aboutOpenSourceLicenses,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                            return const LicenseScreen();
                          },
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.aboutPrivacyPolicy,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
                    onTap: () {
                      launchUrl(Uri.parse('https://jacks-apps.vercel.app/privacy-policy-think-minimal-launcher.html'));
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

