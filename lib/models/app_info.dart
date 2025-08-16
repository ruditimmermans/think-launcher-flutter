import 'dart:typed_data';

enum BuiltWith {
  flutter,
  native,
  unknown,
}

class AppInfo {
  final String name;
  final Uint8List? icon;
  final String packageName;
  final String versionName;
  final int versionCode;
  final BuiltWith builtWith;
  final int installedTimestamp;
  final String? customName;

  AppInfo({
    required this.name,
    this.icon,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.builtWith,
    required this.installedTimestamp,
    this.customName,
  });

  /// Returns the display name - custom name if set, otherwise system name
  String get displayName => customName ?? name;

  /// Creates a copy of this AppInfo with updated fields
  AppInfo copyWith({
    String? name,
    Uint8List? icon,
    String? packageName,
    String? versionName,
    int? versionCode,
    BuiltWith? builtWith,
    int? installedTimestamp,
    String? customName,
  }) {
    return AppInfo(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      builtWith: builtWith ?? this.builtWith,
      installedTimestamp: installedTimestamp ?? this.installedTimestamp,
      customName: customName ?? this.customName,
    );
  }

  factory AppInfo.fromInstalledApps(dynamic app) {
    return AppInfo(
      name: app.name as String,
      icon: app.icon as Uint8List?,
      packageName: app.packageName as String,
      versionName: app.versionName as String,
      versionCode: app.versionCode as int,
      builtWith: BuiltWith.values.firstWhere(
        (e) => e.toString() == 'BuiltWith.${app.builtWith}',
        orElse: () => BuiltWith.unknown,
      ),
      installedTimestamp: app.installedTimestamp as int,
    );
  }

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      name: json['name'] as String,
      icon: json['icon'] as Uint8List?,
      packageName: json['packageName'] as String,
      versionName: json['versionName'] as String,
      versionCode: json['versionCode'] as int,
      builtWith: BuiltWith.values.firstWhere(
        (e) => e.toString() == 'BuiltWith.${json['builtWith']}',
        orElse: () => BuiltWith.unknown,
      ),
      installedTimestamp: json['installedTimestamp'] as int,
      customName: json['customName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'packageName': packageName,
      'versionName': versionName,
      'versionCode': versionCode,
      'builtWith': builtWith.toString().split('.').last,
      'installedTimestamp': installedTimestamp,
      'customName': customName,
    };
  }
}
