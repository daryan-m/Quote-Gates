import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';

class QuoteEditDialog extends StatefulWidget {
  final Quote quote;
  final Function(Quote quote, Color bgColor, Color textColor, String fontFamily)
      onSave;

  const QuoteEditDialog({
    super.key,
    required this.quote,
    required this.onSave,
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

  Future<void> _saveToGallery() async {
    try {
      final Uint8List image = await _screenshotController.captureFromWidget(
        _buildQuotePreview(),
      );
      await Gal.putImageBytes(image, album: "Wisdom Gates");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Quote saved to gallery")),
        );
      }
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
    }
  }

  void _shareQuote() async {
    try {
      final Uint8List image = await _screenshotController.captureFromWidget(
        _buildQuotePreview(),
      );
      await Share.shareXFiles([XFile.fromData(image, name: 'quote.png')]);
    } catch (e) {
      final text = '"${widget.quote.text}" — ${widget.quote.author}';
      await Share.share(text);
    }
  }

  Widget _buildQuotePreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _quoteBgColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.format_quote, size: 50, color: Colors.blueGrey),
          const SizedBox(height: 20),
          Text(
            widget.quote.text,
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: _quoteTextColor,
              fontFamily: _fontFamily == 'System' ? null : _fontFamily,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            "— ${widget.quote.author}",
            style: TextStyle(fontSize: 16, color: _quoteTextColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: _quoteBgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview
            Screenshot(
              controller: _screenshotController,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _quoteBgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.format_quote,
                        color: _quoteTextColor.withValues(alpha: 0.4),
                        size: 32),
                    const SizedBox(height: 12),
                    Text(
                      widget.quote.text,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: _quoteTextColor,
                        fontFamily:
                            _fontFamily == 'System' ? null : _fontFamily,
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
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Background Color",
                        style: TextStyle(
                            color: _quoteTextColor.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bgColors.map((color) {
                        final isSelected = _quoteBgColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _quoteBgColor = color),
                          child: Container(
                            width: 36,
                            height: 36,
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
                    Text("Text Color",
                        style: TextStyle(
                            color: _quoteTextColor.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _textColors.map((color) {
                        final isSelected = _quoteTextColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _quoteTextColor = color),
                          child: Container(
                            width: 36,
                            height: 36,
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
                    Text("Font Style",
                        style: TextStyle(
                            color: _quoteTextColor.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _fonts.map((font) {
                        final isSelected = _fontFamily == font;
                        return GestureDetector(
                          onTap: () => setState(() => _fontFamily = font),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _quoteTextColor.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? _quoteTextColor.withValues(alpha: 0.5)
                                    : _quoteTextColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              font,
                              style: TextStyle(
                                color: _quoteTextColor,
                                fontSize: 12,
                                fontFamily: font == 'System' ? null : font,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel",
                          style: TextStyle(color: _quoteTextColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareQuote,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text("Share"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveToGallery,
                      icon: const Icon(Icons.save_alt, size: 18),
                      label: const Text("Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
