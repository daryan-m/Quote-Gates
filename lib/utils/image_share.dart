import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ImageShare {
  static Future<void> captureAndSave(
    GlobalKey key,
    String quote,
    String author,
  ) async {
    try {
      final boundary =
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
        await ImageGallerySaver.saveFile(path);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}
