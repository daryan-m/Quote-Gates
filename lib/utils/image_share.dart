import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';

class ImageShare {
  static final ScreenshotController _screenshotController =
      ScreenshotController();

  static Future<void> captureAndSave(
    GlobalKey key,
    String quote,
    String author,
  ) async {
    try {
      final Uint8List image = await _screenshotController.captureFromWidget(
        QuoteWidgetForImage(
          quote: quote,
          author: author,
        ),
      );

      await Gal.putImageBytes(
        image,
        album: "Wisdom Gates",
      );
      debugPrint('Image saved to gallery');
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }
}

// ویجێتێکی جیاواز بۆ وێنەگرتن
class QuoteWidgetForImage extends StatelessWidget {
  final String quote;
  final String author;

  const QuoteWidgetForImage({
    super.key,
    required this.quote,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Icon(Icons.format_quote, size: 50, color: Colors.blueGrey),
          const SizedBox(height: 20),
          Text(
            quote,
            style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text("— $author", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
