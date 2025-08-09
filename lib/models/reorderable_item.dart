
import 'package:think_launcher/models/app_info.dart';
import 'package:think_launcher/models/folder.dart';

enum ReorderableItemType {
  app,
  folder,
}

class ReorderableItem {
  final String id;
  final String name;
  final ReorderableItemType type;
  final AppInfo? appInfo;
  final Folder? folder;

  ReorderableItem({
    required this.id,
    required this.name,
    required this.type,
    this.appInfo,
    this.folder,
  });

  factory ReorderableItem.fromApp(AppInfo app) {
    return ReorderableItem(
      id: app.packageName,
      name: app.name,
      type: ReorderableItemType.app,
      appInfo: app,
    );
  }

  factory ReorderableItem.fromFolder(Folder folder) {
    return ReorderableItem(
      id: folder.id,
      name: folder.name,
      type: ReorderableItemType.folder,
      folder: folder,
    );
  }
}
