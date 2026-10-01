import 'dart:io';

import 'package:everslot/design_system/typography.dart';
import 'package:flutter/services.dart';

/// Loads the bundled fonts and Material icons (flutter_test renders every family with its test
/// font otherwise), so goldens show real Inter / Noto Sans Arabic text and icons. Run from the `app/` directory.
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
  // Material icons ship with the Flutter SDK (flutter test sets FLUTTER_ROOT).
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (root != null && icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
  }
}
