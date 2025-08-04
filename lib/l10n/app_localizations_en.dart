// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Think Launcher';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get numberOfApps => 'Number of apps';

  @override
  String get showDateTimeAndBattery => 'Show date, time and battery';

  @override
  String get showSearchButton => 'Show search button';

  @override
  String get showSettingsButton => 'Show settings button';

  @override
  String get longPressGestureDisabled => 'Long press gesture is disabled. Enable it in gesture settings to hide this button.';

  @override
  String get useBoldFont => 'Use bold font';

  @override
  String get enableListScrolling => 'Enable list scrolling';

  @override
  String get showIcons => 'Show icons';

  @override
  String get showStatusBar => 'Show status bar';

  @override
  String get appFontSize => 'App font size';

  @override
  String get appIconSize => 'App icon size';

  @override
  String get appList => 'App list';

  @override
  String appsSelected(int count, int total) {
    return '$count of $total apps selected';
  }

  @override
  String get reorderApps => 'Reorder apps';

  @override
  String get manageFolders => 'Manage folders';

  @override
  String get createAndOrganizeFolders => 'Create and organize app folders';

  @override
  String get gestures => 'Gestures';

  @override
  String get configureGestures => 'Configure application gestures';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get pressSettingsToStart => 'Press the settings button to start';

  @override
  String get loading => 'Loading...';

  @override
  String get errorLoadingApps => 'Error loading applications';

  @override
  String get noAppsSelected => 'No applications selected';

  @override
  String get createFolder => 'Create Folder';

  @override
  String get folderName => 'Folder Name';

  @override
  String get editFolder => 'Edit Folder';

  @override
  String get deleteFolder => 'Delete Folder';

  @override
  String deleteFolderConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String manageAppsInFolder(String name) {
    return 'Manage Apps in $name';
  }

  @override
  String get errorSavingSettings => 'Error saving settings';
}
