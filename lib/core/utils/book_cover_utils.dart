import 'dart:ui' as ui;

/// Google Books serves a generic "image not available" JPEG when no cover exists.
/// It loads successfully but is almost entirely white/light gray pixels.
Future<bool> looksLikePlaceholderCover(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) return false;

  final bytes = byteData.buffer.asUint8List();
  final pixelCount = bytes.length ~/ 4;
  if (pixelCount == 0) return false;

  var lightPixels = 0;
  var samples = 0;
  const step = 12;

  for (var i = 0; i < pixelCount; i += step) {
    final offset = i * 4;
    if (offset + 2 >= bytes.length) break;
    final r = bytes[offset];
    final g = bytes[offset + 1];
    final b = bytes[offset + 2];
    if (r > 215 && g > 215 && b > 215) lightPixels++;
    samples++;
  }

  return samples > 0 && lightPixels / samples > 0.88;
}
