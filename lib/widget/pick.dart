import 'dart:io';

import 'package:path/path.dart' as path;

class PickerNav {
  late final Directory dir;
  late final String name;
  PickerNav({
    required Directory dir,
    String? name,
  }) {
    final abs = dir.absolute;
    this.dir = abs;
    this.name = name ?? path.basename(abs.path);
  }
}
