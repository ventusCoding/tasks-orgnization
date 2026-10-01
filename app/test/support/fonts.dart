import 'dart:io';

import 'package:everslot/design_system/typography.dart';
import 'package:flutter/services.dart';

/// Loads the bundled fonts (flutter_test renders every family with its test font otherwise), so
/// goldens show real Inter / Noto Sans Arabic text. Run from the `app/` directory.
Future<void> loadAppFonts() async {
  Future<void> load(String family, String dir) async {
    final loader = FontLoader(family);
    for (final f in Directory(dir).listSync().whereType<File>().where((f) => f.path.endsWith('.ttf'))) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }

  await load(AppTypography.latin, 'assets/fonts/inter');
  await load(AppTypography.arabic, 'assets/fonts/noto_sans_arabic');
}
