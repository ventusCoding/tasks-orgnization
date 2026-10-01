import 'dart:io';
import 'dart:typed_data';

import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/attachments/application/attachment_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'attachment_domain_test.dart' show jpegBytes, pngBytes;

/// Clipboard source of the platform picker with a fake clipboard (T4.4.09).
void main() {
  late Directory dir;
  Uint8List? clipboard;
  final picker = PlatformAttachmentPicker(
    clock: FakeClock(DateTime.utc(2026, 9, 22, 14, 5)),
    readClipboardImage: () async => clipboard,
    tempDir: () async => dir,
  );

  setUp(() => dir = Directory.systemTemp.createTempSync('clip'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('an image on the clipboard becomes a named temporary file', () async {
    clipboard = pngBytes(40, 30);
    final picked = (await picker.pick(AttachmentSource.clipboard)).single;
    expect(picked.name, matches(RegExp(r'^Pasted image 2026-09-22 \d\d\.05\.png$')));
    expect(picked.mimeType, 'image/png');
    expect(File(picked.path).readAsBytesSync(), clipboard);

    clipboard = jpegBytes(40, 30);
    expect((await picker.pick(AttachmentSource.clipboard)).single.name, endsWith('.jpg'));
  });

  test('no image or non-image bytes pick nothing', () async {
    clipboard = null;
    expect(await picker.pick(AttachmentSource.clipboard), isEmpty);
    clipboard = Uint8List.fromList(List.filled(64, 7));
    expect(await picker.pick(AttachmentSource.clipboard), isEmpty);
    expect(await picker.fromImageBytes(Uint8List(0)), isNull);
  });
}
