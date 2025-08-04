import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Think Launcher'**
  String get appTitle;

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Label for number of apps setting
  ///
  /// In en, this message translates to:
  /// **'Number of apps'**
  String get numberOfApps;

  /// Label for date time and battery setting
  ///
  /// In en, this message translates to:
  /// **'Show date, time and battery'**
  String get showDateTimeAndBattery;

  /// Label for search button visibility setting
  ///
  /// In en, this message translates to:
  /// **'Show search button'**
  String get showSearchButton;

  /// Label for settings button visibility setting
  ///
  /// In en, this message translates to:
  /// **'Show settings button'**
  String get showSettingsButton;

  /// Message shown when long press gesture is disabled
  ///
  /// In en, this message translates to:
  /// **'Long press gesture is disabled. Enable it in gesture settings to hide this button.'**
  String get longPressGestureDisabled;

  /// Label for bold font setting
  ///
  /// In en, this message translates to:
  /// **'Use bold font'**
  String get useBoldFont;

  /// Label for list scrolling setting
  ///
  /// In en, this message translates to:
  /// **'Enable list scrolling'**
  String get enableListScrolling;

  /// Label for icon visibility setting
  ///
  /// In en, this message translates to:
  /// **'Show icons'**
  String get showIcons;

  /// Label for status bar visibility setting
  ///
  /// In en, this message translates to:
  /// **'Show status bar'**
  String get showStatusBar;

  /// Label for app font size setting
  ///
  /// In en, this message translates to:
  /// **'App font size'**
  String get appFontSize;

  /// Label for app icon size setting
  ///
  /// In en, this message translates to:
  /// **'App icon size'**
  String get appIconSize;

  /// Label for app list section
  ///
  /// In en, this message translates to:
  /// **'App list'**
  String get appList;

  /// Shows how many apps are selected out of total
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} apps selected'**
  String appsSelected(int count, int total);

  /// Label for reorder apps option
  ///
  /// In en, this message translates to:
  /// **'Reorder apps'**
  String get reorderApps;

  /// Label for manage folders option
  ///
  /// In en, this message translates to:
  /// **'Manage folders'**
  String get manageFolders;

  /// Description for manage folders option
  ///
  /// In en, this message translates to:
  /// **'Create and organize app folders'**
  String get createAndOrganizeFolders;

  /// Label for gestures option
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get gestures;

  /// Description for gestures option
  ///
  /// In en, this message translates to:
  /// **'Configure application gestures'**
  String get configureGestures;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Message shown when no apps are selected
  ///
  /// In en, this message translates to:
  /// **'Press the settings button to start'**
  String get pressSettingsToStart;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error message when apps fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading applications'**
  String get errorLoadingApps;

  /// Message shown when no apps are selected
  ///
  /// In en, this message translates to:
  /// **'No applications selected'**
  String get noAppsSelected;

  /// Title for create folder dialog
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createFolder;

  /// Label for folder name input
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// Title for edit folder dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Folder'**
  String get editFolder;

  /// Title for delete folder dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get deleteFolder;

  /// Confirmation message for folder deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteFolderConfirm(String name);

  /// Title for manage apps in folder dialog
  ///
  /// In en, this message translates to:
  /// **'Manage Apps in {name}'**
  String manageAppsInFolder(String name);

  /// Error message shown when settings fail to save
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get errorSavingSettings;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'nl': return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
