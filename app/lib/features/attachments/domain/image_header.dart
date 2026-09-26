import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Basic facts read from an image header without decoding pixels (T2.2.03).
@immutable
class ImageHeader {
  const ImageHeader({
    required this.format,
    required this.width,
    required this.height,
    this.hasAlpha = false,
    this.exifOrientation = 1,
  });

  /// jpeg | png | gif | webp | bmp
  final String format;
  final int width;
  final int height;
  final bool hasAlpha;

  /// EXIF orientation 1–8 (JPEG only; 1 = upright).
  final int exifOrientation;

  /// Dimensions as displayed once the EXIF orientation is applied.
  (int, int) get orientedSize => exifOrientation >= 5 ? (height, width) : (width, height);

  @override
  String toString() => 'ImageHeader($format ${width}x$height alpha=$hasAlpha o=$exifOrientation)';
}

/// Pure parser for PNG / JPEG / GIF / WebP / BMP headers.
abstract final class ImageHeaderParser {
  static ImageHeader? parse(Uint8List b) {
    if (b.length < 12) return null;
    if (_isPng(b)) return _png(b);
    if (b[0] == 0xFF && b[1] == 0xD8) return _jpeg(b);
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) return _gif(b);
    if (_ascii(b, 0, 4) == 'RIFF' && _ascii(b, 8, 4) == 'WEBP') return _webp(b);
    if (b[0] == 0x42 && b[1] == 0x4D && b.length >= 26) return _bmp(b);
    return null;
  }

  static bool _isPng(Uint8List b) =>
      b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47 && b[4] == 0x0D && b[5] == 0x0A;

  static String _ascii(Uint8List b, int start, int length) {
    if (start + length > b.length) return '';
    return String.fromCharCodes(b.sublist(start, start + length));
  }

  static int _be32(Uint8List b, int o) => (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
  static int _be16(Uint8List b, int o) => (b[o] << 8) | b[o + 1];
  static int _le16(Uint8List b, int o) => b[o] | (b[o + 1] << 8);
  static int _le24(Uint8List b, int o) => b[o] | (b[o + 1] << 8) | (b[o + 2] << 16);
  static int _le32(Uint8List b, int o) => b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

  static ImageHeader? _png(Uint8List b) {
    if (b.length < 26 || _ascii(b, 12, 4) != 'IHDR') return null;
    final w = _be32(b, 16);
    final h = _be32(b, 20);
    final colorType = b[25];
    var alpha = colorType == 4 || colorType == 6;
    if (!alpha) {
      // Look for a tRNS chunk (palette/greyscale transparency).
      var o = 8;
      while (o + 8 <= b.length) {
        final len = _be32(b, o);
        final type = _ascii(b, o + 4, 4);
        if (type == 'tRNS') {
          alpha = true;
          break;
        }
        if (type == 'IDAT' || type == 'IEND') break;
        o += 12 + len;
      }
    }
    return ImageHeader(format: 'png', width: w, height: h, hasAlpha: alpha);
  }

  static ImageHeader? _jpeg(Uint8List b) {
    var o = 2;
    var orientation = 1;
    while (o + 4 <= b.length) {
      if (b[o] != 0xFF) {
        o++;
        continue;
      }
      final marker = b[o + 1];
      if (marker == 0xD8 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
        o += 2;
        continue;
      }
      if (marker == 0xFF) {
        o++;
        continue;
      }
      final len = _be16(b, o + 2);
      if (marker == 0xE1 && _ascii(b, o + 4, 4) == 'Exif') {
        orientation = _exifOrientation(b, o + 10, len - 8) ?? orientation;
      }
      final isSof = marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
      if (isSof && o + 9 <= b.length) {
        final h = _be16(b, o + 5);
        final w = _be16(b, o + 7);
        return ImageHeader(format: 'jpeg', width: w, height: h, exifOrientation: orientation);
      }
      if (marker == 0xDA) break;
      o += 2 + len;
    }
    return null;
  }

  static int? _exifOrientation(Uint8List b, int tiff, int length) {
    if (tiff + 8 > b.length) return null;
    final little = b[tiff] == 0x49 && b[tiff + 1] == 0x49;
    int r16(int o) => little ? _le16(b, o) : _be16(b, o);
    int r32(int o) => little ? _le32(b, o) : _be32(b, o);
    final ifd = tiff + r32(tiff + 4);
    if (ifd + 2 > b.length) return null;
    final count = r16(ifd);
    for (var i = 0; i < count; i++) {
      final e = ifd + 2 + i * 12;
      if (e + 12 > b.length) return null;
      if (r16(e) == 0x0112) {
        final v = r16(e + 8);
        return v >= 1 && v <= 8 ? v : 1;
      }
    }
    return null;
  }

  static ImageHeader _gif(Uint8List b) =>
      ImageHeader(format: 'gif', width: _le16(b, 6), height: _le16(b, 8), hasAlpha: true);

  static ImageHeader? _webp(Uint8List b) {
    final chunk = _ascii(b, 12, 4);
    if (chunk == 'VP8 ' && b.length >= 30) {
      return ImageHeader(format: 'webp', width: _le16(b, 26) & 0x3FFF, height: _le16(b, 28) & 0x3FFF);
    }
    if (chunk == 'VP8L' && b.length >= 25) {
      final bits = _le32(b, 21);
      return ImageHeader(
        format: 'webp',
        width: (bits & 0x3FFF) + 1,
        height: ((bits >> 14) & 0x3FFF) + 1,
        hasAlpha: ((bits >> 28) & 1) == 1,
      );
    }
    if (chunk == 'VP8X' && b.length >= 30) {
      return ImageHeader(
        format: 'webp',
        width: _le24(b, 24) + 1,
        height: _le24(b, 27) + 1,
        hasAlpha: (b[20] & 0x10) != 0,
      );
    }
    return null;
  }

  static ImageHeader _bmp(Uint8List b) =>
      ImageHeader(format: 'bmp', width: _le32(b, 18).abs(), height: _le32(b, 22).toSigned(32).abs());
}

/// Removes metadata segments (APP1 EXIF/XMP incl. GPS, APP2–APP15, comments) from a JPEG.
///
/// Used as the privacy fallback when the native re-encoder is unavailable (T2.2.03). The image
/// data itself is untouched; the orientation tag is lost with EXIF, so the caller should prefer
/// re-encoding (which bakes the orientation in) whenever possible.
Uint8List stripJpegMetadata(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return b;
  final out = BytesBuilder(copy: false)..add([0xFF, 0xD8]);
  var o = 2;
  while (o + 4 <= b.length) {
    if (b[o] != 0xFF) return b; // corrupt: leave untouched
    final marker = b[o + 1];
    if (marker == 0xDA) {
      out.add(b.sublist(o));
      return out.toBytes();
    }
    final len = (b[o + 2] << 8) | b[o + 3];
    final end = o + 2 + len;
    if (end > b.length) return b;
    final isMetadata = (marker >= 0xE1 && marker <= 0xEF) || marker == 0xFE;
    if (!isMetadata) out.add(b.sublist(o, end));
    o = end;
  }
  return b;
}
