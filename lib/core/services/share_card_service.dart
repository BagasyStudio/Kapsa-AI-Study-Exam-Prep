import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a RepaintBoundary widget as a PNG image and shares it.
class ShareCardService {
  /// Capture the widget behind [key] as a PNG and open the native share sheet.
  static Future<bool> captureAndShare(
    GlobalKey key, {
    String? shareText,
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return false;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/kapsa_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: shareText ?? 'Study smarter with Kapsa ✨',
        ),
      );

      // Cleanup temp file after a delay
      Future.delayed(const Duration(seconds: 30), () {
        file.delete().catchError((_) => file);
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}
