class NotificationInfo {
  final String packageName;
  final String title;
  final String content;
  final int id;
  final bool onGoing;

  NotificationInfo({
    required this.packageName,
    required this.title,
    required this.content,
    required this.id,
    required this.onGoing,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationInfo &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          id == other.id;

  @override
  int get hashCode => packageName.hashCode ^ id.hashCode;
}