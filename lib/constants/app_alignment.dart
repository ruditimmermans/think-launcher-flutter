enum AppAlignment {
  left,
  center,
  right,
}

const String _kAppAlignmentLeft = 'left';
const String _kAppAlignmentCenter = 'center';
const String _kAppAlignmentRight = 'right';

extension AppAlignmentStorage on AppAlignment {
  String get storageKey {
    switch (this) {
      case AppAlignment.left:
        return _kAppAlignmentLeft;
      case AppAlignment.center:
        return _kAppAlignmentCenter;
      case AppAlignment.right:
        return _kAppAlignmentRight;
    }
  }
}

AppAlignment appAlignmentFromStorage(String? value) {
  switch (value) {
    case _kAppAlignmentCenter:
      return AppAlignment.center;
    case _kAppAlignmentRight:
      return AppAlignment.right;
    case _kAppAlignmentLeft:
    default:
      return AppAlignment.left;
  }
}
