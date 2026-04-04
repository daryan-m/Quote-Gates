import 'package:flutter/material.dart';
import '../models/quote.dart';

class QuoteEditDialog extends StatefulWidget {
  final Quote quote;
  final Color bgColor;
  final String fontFamily;
  final Function(Quote quote, Color bgColor, String fontFamily) onSave;

  const QuoteEditDialog({
    super.key,
    required this.quote,
    required this.bgColor,
    required this.fontFamily,
    required this.onSave,
  });

  @override
  State<QuoteEditDialog> createState() => _QuoteEditDialogState();
}

class _QuoteEditDialogState extends State<QuoteEditDialog> {
  late TextEditingController _quoteController;
  late TextEditingController _authorController;
  late Color _bgColor;
  late Color _textColor; // ✅ ناو چاکەکرا
  late String _fontFamily;

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

  // ✅ ناو چاکەکرا، بەکاردەهێنرێت بۆ color picker
  final List<Color> _textColorOptions = [
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
  ];

  @override
  void initState() {
    super.initState();
    _quoteController = TextEditingController(text: widget.quote.text);
    _authorController = TextEditingController(text: widget.quote.author);
    _bgColor = widget.bgColor;
    _fontFamily = widget.fontFamily;
    _textColor = widget.bgColor.computeLuminance() < 0.5 // ✅
        ? Colors.white
        : const Color(0xFF2C2C2C);
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _textColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.format_quote,
                      color: _textColor.withValues(alpha: 0.4), size: 28),
                  const SizedBox(height: 8),
                  Text(
                    _quoteController.text.isEmpty
                        ? "Your quote here..."
                        : _quoteController.text,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: _textColor,
                      fontFamily: _fontFamily == 'System' ? null : _fontFamily,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "— ${_authorController.text.isEmpty ? 'Author' : _authorController.text}",
                    style: TextStyle(
                        fontSize: 12, color: _textColor.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _quoteController,
                      style: TextStyle(color: _textColor, fontSize: 13),
                      maxLines: 3,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Edit quote...",
                        hintStyle: TextStyle(
                            color: _textColor.withValues(alpha: 0.4),
                            fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _textColor.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _textColor.withValues(alpha: 0.15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _authorController,
                      style: TextStyle(color: _textColor, fontSize: 13),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Author name...",
                        hintStyle: TextStyle(
                            color: _textColor.withValues(alpha: 0.4),
                            fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _textColor.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _textColor.withValues(alpha: 0.15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ڕەنگی باکگراوند
                    Text("Background Color",
                        style: TextStyle(
                            color: _textColor.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bgColors.map((color) {
                        final isSelected = _bgColor == color;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _bgColor = color;
                            _textColor = color.computeLuminance() < 0.5
                                ? Colors.white
                                : const Color(0xFF2C2C2C);
                          }),
                          child: Container(
                            width: 32,
                            height: 32,
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
                    const SizedBox(height: 12),

                    // ✅ ڕەنگی تێکست — تازە زیادکرا
                    Text("Text Color",
                        style: TextStyle(
                            color: _textColor.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _textColorOptions.map((color) {
                        final isSelected = _textColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _textColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
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
                    const SizedBox(height: 12),

                    // فۆنت
                    Text("Font Style",
                        style: TextStyle(
                            color: _textColor.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: _fonts.map((font) {
                        final isSelected = _fontFamily == font;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _fontFamily = font),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _textColor.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? _textColor.withValues(alpha: 0.5)
                                      : _textColor.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                font,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 12,
                                  fontFamily: font == 'System' ? null : font,
                                ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child:
                          Text("Cancel", style: TextStyle(color: _textColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final updatedQuote = Quote(
                          text: _quoteController.text,
                          author: _authorController.text,
                          category: widget.quote.category,
                        );
                        widget.onSave(updatedQuote, _bgColor, _fontFamily);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _textColor,
                        foregroundColor: _bgColor,
                      ),
                      child: const Text("Save"),
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
