// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Think Launcher';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get numberOfApps => 'Aantal apps';

  @override
  String get showDateTimeAndBattery => 'Toon datum, tijd en batterij';

  @override
  String get showSearchButton => 'Toon zoekknop';

  @override
  String get showSettingsButton => 'Toon instellingenknop';

  @override
  String get longPressGestureDisabled => 'Lang indrukken is uitgeschakeld. Schakel het in bij gebarinstellingen om deze knop te verbergen.';

  @override
  String get useBoldFont => 'Gebruik vet lettertype';

  @override
  String get enableListScrolling => 'Scrollen in lijst inschakelen';

  @override
  String get showIcons => 'Toon pictogrammen';

  @override
  String get showStatusBar => 'Toon statusbalk';

  @override
  String get appFontSize => 'App lettergrootte';

  @override
  String get appIconSize => 'App pictogramgrootte';

  @override
  String get appList => 'App lijst';

  @override
  String appsSelected(int count, int total) {
    return '$count van $total apps geselecteerd';
  }

  @override
  String get reorderApps => 'Apps herschikken';

  @override
  String get manageFolders => 'Mappen beheren';

  @override
  String get createAndOrganizeFolders => 'Maak en organiseer app-mappen';

  @override
  String get gestures => 'Gebaren';

  @override
  String get configureGestures => 'Configureer app-gebaren';

  @override
  String get save => 'Opslaan';

  @override
  String get cancel => 'Annuleren';

  @override
  String get pressSettingsToStart => 'Druk op de instellingenknop om te beginnen';

  @override
  String get loading => 'Laden...';

  @override
  String get errorLoadingApps => 'Fout bij laden van applicaties';

  @override
  String get noAppsSelected => 'Geen applicaties geselecteerd';

  @override
  String get createFolder => 'Map maken';

  @override
  String get folderName => 'Mapnaam';

  @override
  String get editFolder => 'Map bewerken';

  @override
  String get deleteFolder => 'Map verwijderen';

  @override
  String deleteFolderConfirm(String name) {
    return 'Weet je zeker dat je \"$name\" wilt verwijderen?';
  }

  @override
  String manageAppsInFolder(String name) {
    return 'Apps beheren in $name';
  }

  @override
  String get errorSavingSettings => 'Fout bij opslaan van instellingen';
}
