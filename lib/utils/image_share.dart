import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:saver_gallery/saver_gallery.dart'; // گۆڕا
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ImageShare {
  static Future<void> captureAndShare(
    GlobalKey key,
    String quote,
    String author,
  ) async {
    try {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/wisdom_quote.png';
        final File file = File(path);
        await file.writeAsBytes(byteData.buffer.asUint8List());

        // هەڵگرتن لە گالێری
        await SaverGallery.saveImage(
  byteData.buffer.asUint8List(),
  quality: 100,
  fileName: 'wisdom_quote',
  skipIfExists: false,
  androidRelativePath: 'Pictures/WisdomApp',
);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}