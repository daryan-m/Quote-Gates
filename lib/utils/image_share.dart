import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ImageShare {
  // وێنەگرتن لە ویجێتێک و هاوبەشکردنی
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
        await Gal.putImage(path);

        // پیشاندانی پیام
        // تێبینی: بۆ share کردن ڕاستەوخۆ پێویستی بە share_plus پاکێجە
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}
