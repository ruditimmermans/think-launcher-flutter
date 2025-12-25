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
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.aboutTitle),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          backgroundColor: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(versionText),
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.aboutOpenSourceLicenses,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
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

