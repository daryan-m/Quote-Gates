import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';

class QuoteEditDialog extends StatefulWidget {
  final Quote quote;
  final bool isPremium;

  const QuoteEditDialog({
    super.key,
    required this.quote,
    this.isPremium = false,
  });

  @override
  State<QuoteEditDialog> createState() => _QuoteEditDialogState();
}

class _QuoteEditDialogState extends State<QuoteEditDialog>
    with TickerProviderStateMixin {
  late Color _quoteBgColor;
  late Color _quoteTextColor;
  late String _fontFamily;
  int _selectedBgIndex = 0;
  int _selectedTextIndex = 0;
  int _selectedFontIndex = 0;

  final ScreenshotController _screenshotController = ScreenshotController();
  late AnimationController _previewController;
  late Animation<double> _previewAnimation;

  // ---- رەنگەکانی باکگراوند ----
  final List<_ColorItem> _bgColors = const [
    _ColorItem(color: Colors.white, label: 'White'),
    _ColorItem(color: Color(0xFFF8F6F0), label: 'Cream'),
    _ColorItem(color: Color(0xFFFFF8E7), label: 'Warm'),
    _ColorItem(color: Color(0xFFE8F5E9), label: 'Mint'),
    _ColorItem(color: Color(0xFFE3F2FD), label: 'Sky'),
    _ColorItem(color: Color(0xFFFCE4EC), label: 'Rose'),
    _ColorItem(color: Color(0xFF1A1A1A), label: 'Black'),
    _ColorItem(color: Color(0xFF1A1A2E), label: 'Night'),
    _ColorItem(color: Color(0xFF16213E), label: 'Navy'),
    _ColorItem(color: Color(0xFF0F3460), label: 'Ocean'),
    _ColorItem(color: Color(0xFF1B4332), label: 'Forest'),
    _ColorItem(color: Color(0xFF6B2D8B), label: 'Purple'),
    _ColorItem(color: Color(0xFF7B3F00), label: 'Coffee'),
    _ColorItem(color: Color(0xFF880E4F), label: 'Berry'),
  ];

  // ---- رەنگەکانی تێکست ----
  final List<_ColorItem> _textColors = const [
    _ColorItem(color: Color(0xFF2C2C2C), label: 'Dark'),
    _ColorItem(color: Colors.white, label: 'White'),
    _ColorItem(color: Colors.black, label: 'Black'),
    _ColorItem(color: Color(0xFFE0E0E0), label: 'Silver'),
    _ColorItem(color: Color(0xFFFFD700), label: 'Gold'),
    _ColorItem(color: Color(0xFF4CAF50), label: 'Green'),
    _ColorItem(color: Color(0xFF2196F3), label: 'Blue'),
    _ColorItem(color: Colors.orange, label: 'Orange'),
    _ColorItem(color: Color(0xFFFF7043), label: 'Coral'),
    _ColorItem(color: Color(0xFFAB47BC), label: 'Violet'),
  ];

  // ---- فۆنتەکان ----
  final List<_FontItem> _fonts = const [
    _FontItem(name: 'System', display: 'System'),
    _FontItem(name: 'Serif', display: 'Serif'),
    _FontItem(name: 'Monospace', display: 'Mono'),
    _FontItem(name: 'CabinSketch', display: 'Sketch'),
    _FontItem(name: 'Caveat', display: 'Caveat'),
    _FontItem(name: 'DancingScript', display: 'Dance'),
    _FontItem(name: 'Lobster', display: 'Lobster'),
    _FontItem(name: 'LobsterTwo', display: 'Lobster2'),
  ];

  @override
  void initState() {
    super.initState();
    _quoteBgColor = _bgColors[0].color;
    _quoteTextColor = _textColors[0].color;
    _fontFamily = _fonts[0].name;

    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _previewAnimation = CurvedAnimation(
      parent: _previewController,
      curve: Curves.easeOutCubic,
    );
    _previewController.forward();
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  void _selectBg(int index) {
    setState(() {
      _selectedBgIndex = index;
      _quoteBgColor = _bgColors[index].color;
    });
    _previewController
      ..reset()
      ..forward();
  }

  void _selectText(int index) {
    setState(() {
      _selectedTextIndex = index;
      _quoteTextColor = _textColors[index].color;
    });
  }

  void _selectFont(int index) {
    setState(() {
      _selectedFontIndex = index;
      _fontFamily = _fonts[index].name;
    });
  }

  Future<Uint8List> _captureQuoteImage() async {
    return await _screenshotController.captureFromWidget(
      Material(
        color: Colors.transparent,
        child: Container(
          width: 1080,
          padding: const EdgeInsets.all(80),
          decoration: BoxDecoration(
            color: _quoteBgColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ئایکۆنی گفتووگۆ
              Icon(
                Icons.format_quote_rounded,
                size: 80,
                color: _quoteTextColor.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 40),
              // تێکستی وتە
              Text(
                widget.quote.text,
                style: TextStyle(
                  fontSize: 52,
                  fontStyle: FontStyle.italic,
                  color: _quoteTextColor,
                  fontFamily: _fontFamily == 'System' ? null : _fontFamily,
                  height: 1.55,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // هێڵی جیاکەر
              Container(
                width: 80,
                height: 2,
                decoration: BoxDecoration(
                  color: _quoteTextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 28),
              // ناوی نووسەر
              Text(
                "— ${widget.quote.author}",
                style: TextStyle(
                  fontSize: 36,
                  color: _quoteTextColor.withValues(alpha: 0.7),
                  fontFamily: _fontFamily == 'System' ? null : _fontFamily,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 60),
              // واتەرمارک
              Text(
                "Wisdom Gates",
                style: TextStyle(
                  fontSize: 22,
                  color: _quoteTextColor.withValues(alpha: 0.18),
                  letterSpacing: 4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      pixelRatio: 1.0,
    );
  }

  Future<void> _shareQuote({String? platform}) async {
    final image = await _captureQuoteImage();
    final file = XFile.fromData(
      image,
      name: 'wisdom_quote.png',
      mimeType: 'image/png',
    );

    if (platform != null) {
      // شەریکردن بە پلاتفۆرمی تایبەت
      await Share.shareXFiles(
        [file],
        text:
            '"${widget.quote.text}"\n— ${widget.quote.author}\n\n#WisdomGates #Quotes',
      );
    } else {
      await Share.shareXFiles([file]);
    }
  }

  Future<void> _saveToGallery() async {
    final image = await _captureQuoteImage();
    await Gal.putImageBytes(image, album: "Wisdom Gates");
    if (mounted) {
      _showToast("Saved to gallery!");
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.blueGrey.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final isDarkBg = _quoteBgColor.computeLuminance() < 0.5;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        // ئارتەفاکتی پێداگریکراو: بەرزی زیاکراوە بۆ ریسپۆنسیڤی باشتر
        constraints: BoxConstraints(
          maxHeight: screenH * 0.88,
          maxWidth: 520,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── هێڵی سەرەوە ──
            _buildHeader(),

            // ── پرێڤیوی وتە ──
            AnimatedBuilder(
              animation: _previewAnimation,
              builder: (_, child) => Opacity(
                opacity: _previewAnimation.value,
                child: Transform.scale(
                  scale: 0.96 + 0.04 * _previewAnimation.value,
                  child: child,
                ),
              ),
              child: _buildPreview(isDarkBg),
            ),

            const Divider(height: 1),

            // ── بەشی دەستکاری ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Background"),
                    const SizedBox(height: 10),
                    _buildColorGrid(
                      items: _bgColors,
                      selectedIndex: _selectedBgIndex,
                      onTap: _selectBg,
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle("Text Color"),
                    const SizedBox(height: 10),
                    _buildColorGrid(
                      items: _textColors,
                      selectedIndex: _selectedTextIndex,
                      onTap: _selectText,
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle("Font Style"),
                    const SizedBox(height: 10),
                    _buildFontGrid(),
                    const SizedBox(height: 18),
                    _sectionTitle("Share to"),
                    const SizedBox(height: 10),
                    _buildShareRow(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // ── دوگمەکانی خوارەوە ──
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  // ── سەرپەڕەی دیالۆگ ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.palette_outlined, color: Colors.blueGrey, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Customize & Share",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── پرێڤیوی وتە ──
  Widget _buildPreview(bool isDarkBg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: _quoteBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkBg
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: _quoteTextColor.withValues(alpha: 0.22),
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            widget.quote.text,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: _quoteTextColor,
              fontFamily: _fontFamily == 'System' ? null : _fontFamily,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 1.5,
            color: _quoteTextColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),
          Text(
            "— ${widget.quote.author}",
            style: TextStyle(
              fontSize: 13,
              color: _quoteTextColor.withValues(alpha: 0.6),
              fontFamily: _fontFamily == 'System' ? null : _fontFamily,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── سەردێڕی بەش ──
  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Colors.blueGrey,
        ),
      );

  // ── گریدی رەنگ ── ریسپۆنسیڤ و لەبلەدار
  Widget _buildColorGrid({
    required List<_ColorItem> items,
    required int selectedIndex,
    required void Function(int) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isSelected = selectedIndex == i;
        final isDark = item.color.computeLuminance() < 0.5;
        return GestureDetector(
          onTap: () => onTap(i),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blueGrey : Colors.grey.shade300,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.blueGrey.withValues(alpha: 0.25),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.blueGrey.shade700
                      : Colors.grey.shade500,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── گریدی فۆنت ──
  Widget _buildFontGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_fonts.length, (i) {
        final font = _fonts[i];
        final isSelected = _selectedFontIndex == i;
        return GestureDetector(
          onTap: () => _selectFont(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueGrey : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? Colors.blueGrey : Colors.grey.shade300,
                width: 1.2,
              ),
            ),
            child: Text(
              font.display,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 13,
                fontFamily: font.name == 'System' ? null : font.name,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── ئایکۆنەکانی پلاتفۆرم ──
  Widget _buildShareRow() {
    const platforms = [
      _PlatformItem(
        icon: Icons.camera_alt_outlined,
        label: 'Instagram',
        color: Color(0xFFE1306C),
      ),
      _PlatformItem(
        icon: Icons.facebook_outlined,
        label: 'Facebook',
        color: Color(0xFF1877F2),
      ),
      _PlatformItem(
        icon: Icons.message_outlined,
        label: 'WhatsApp',
        color: Color(0xFF25D366),
      ),
      _PlatformItem(
        icon: Icons.message_outlined,
        label: 'Viber',
        color: Color(0xFF7360F2),
      ),
      _PlatformItem(
        icon: Icons.send_outlined,
        label: 'Telegram',
        color: Color(0xFF0088CC),
      ),
      _PlatformItem(
        icon: Icons.share_outlined,
        label: 'More',
        color: Colors.blueGrey,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: platforms.map((p) {
        return GestureDetector(
          onTap: () => _shareQuote(platform: p.label),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: p.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: p.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(p.icon, color: p.color, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                p.label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── دوگمەکانی خوارەوە ──
  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          // دوگمەی ذەخیرەکردن لە گەلری
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saveToGallery,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text("Save"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: Colors.blueGrey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // دوگمەی شەریکردن
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _shareQuote(),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text("Share Quote"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── موودێلەکانی یارمەتیدەر ──
class _ColorItem {
  final Color color;
  final String label;
  const _ColorItem({required this.color, required this.label});
}

class _FontItem {
  final String name;
  final String display;
  const _FontItem({required this.name, required this.display});
}

class _PlatformItem {
  final IconData icon;
  final String label;
  final Color color;
  const _PlatformItem(
      {required this.icon, required this.label, required this.color});
}
