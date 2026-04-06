import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';

class QuoteEditDialog extends StatefulWidget {
  final Quote quote;

  const QuoteEditDialog({
    super.key,
    required this.quote,
  });

  @override
  State<QuoteEditDialog> createState() => _QuoteEditDialogState();
}

class _QuoteEditDialogState extends State<QuoteEditDialog> {
  late Color _quoteBgColor;
  late Color _quoteTextColor;
  late String _fontFamily;
  final ScreenshotController _screenshotController = ScreenshotController();

  final List<Color> _bgColors = [
    const Color(0xFFF8F6F0),
    Colors.white,
    const Color(0xFF1A1A2E),
    const Color(0xFF16213E),
    const Color(0xFF0F3460),
    const Color(0xFF1B4332),
    const Color(0xFF6B2D8B),
    const Color(0xFF7B3F00),
    const Color(0xFF1A1A1A),
    const Color(0xFFFFF8E7),
    const Color(0xFFE8F5E9),
    const Color(0xFFE3F2FD),
  ];

  final List<Color> _textColors = [
    const Color(0xFF2C2C2C),
    Colors.white,
    Colors.black,
    const Color(0xFFE0E0E0),
    const Color(0xFFFFD700),
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    Colors.orange,
  ];

  final List<String> _fonts = [
    'System',
    'Serif',
    'Monospace',
    'CabinSketch',
    'Caveat',
    'DancingScript',
    'Lobster',
    'LobsterTwo'
  ];

  @override
  void initState() {
    super.initState();
    _quoteBgColor = Colors.white;
    _quoteTextColor = const Color(0xFF2C2C2C);
    _fontFamily = 'System';
  }

  Future<Uint8List> _captureQuoteImage() async {
    return await _screenshotController.captureFromWidget(
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _quoteBgColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_quote, size: 60, color: Colors.blueGrey),
            const SizedBox(height: 24),
            Text(
              widget.quote.text,
              style: TextStyle(
                fontSize: 24,
                fontStyle: FontStyle.italic,
                color: _quoteTextColor,
                fontFamily: _fontFamily == 'System' ? null : _fontFamily,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              "— ${widget.quote.author}",
              style: TextStyle(fontSize: 18, color: _quoteTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQuote() async {
    final image = await _captureQuoteImage();
    await Share.shareXFiles([XFile.fromData(image, name: 'quote.png')]);
  }

  Future<void> _saveToGallery() async {
    final image = await _captureQuoteImage();
    await Gal.putImageBytes(image, album: "Wisdom Gates");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quote saved to gallery")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
  
    

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _quoteBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.format_quote,
                      color: _quoteTextColor.withValues(alpha: 0.4), size: 40),
                  const SizedBox(height: 12),
                  Text(
                    widget.quote.text,
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: _quoteTextColor,
                      fontFamily: _fontFamily == 'System' ? null : _fontFamily,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "— ${widget.quote.author}",
                    style: TextStyle(
                        fontSize: 14,
                        color: _quoteTextColor.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Background Color",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bgColors.map((color) {
                        final isSelected = _quoteBgColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _quoteBgColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: isSelected
                                ? Icon(Icons.check,
                                    size: 16,
                                    color: color.computeLuminance() < 0.5
                                        ? Colors.white
                                        : Colors.black)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text("Text Color",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _textColors.map((color) {
                        final isSelected = _quoteTextColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _quoteTextColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: isSelected
                                ? Icon(Icons.check,
                                    size: 16,
                                    color: color.computeLuminance() < 0.5
                                        ? Colors.white
                                        : Colors.black)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text("Font Style",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _fonts.map((font) {
                        final isSelected = _fontFamily == font;
                        return GestureDetector(
                          onTap: () => setState(() => _fontFamily = font),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blueGrey
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blueGrey
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              font,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontSize: 12,
                                fontFamily: font == 'System' ? null : font,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // دوگمەکان
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _shareQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Share"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveToGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
