class Folder {
  final String id;
  final String name;
  final List<String> appPackageNames;

  const Folder({
    required this.id,
    required this.name,
    required this.appPackageNames,
  });

  Folder copyWith({
    String? name,
    List<String>? appPackageNames,
  }) {
    return Folder(
      id: id,
      name: name ?? this.name,
      appPackageNames: appPackageNames ?? this.appPackageNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'appPackageNames': appPackageNames,
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      appPackageNames: List<String>.from(json['appPackageNames'] as List),
    );
  }
}