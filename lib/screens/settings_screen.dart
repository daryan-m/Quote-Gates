import 'package:flutter/material.dart';
import '../services/purchase_service.dart';
import '../widgets/upgrade_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final Color bgColor;
  final String fontFamily;
  final String dailyQuoteTime;
  final Function(Color color, String font, String time) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.bgColor,
    required this.fontFamily,
    required this.dailyQuoteTime,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Color _bgColor;
  late String _fontFamily;
  late String _dailyQuoteTime;
  late double _fontSize;
  late Color _textColor;
  bool _isPro = false;

  // ── تیمەکان ────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _themes = [
    {'label': 'Ivory', 'color': const Color(0xFFF8F6F0)},
    {'label': 'Cloud', 'color': const Color(0xFFFFFFFF)},
    {'label': 'Slate', 'color': const Color(0xFF2C3E50)},
    {'label': 'Cosmos', 'color': const Color(0xFF1A1A2E)},
    {'label': 'Ocean', 'color': const Color(0xFF0F3460)},
    {'label': 'Forest', 'color': const Color(0xFF1B4332)},
    {'label': 'Plum', 'color': const Color(0xFF4A235A)},
    {'label': 'Mocha', 'color': const Color(0xFF3E2723)},
    {'label': 'Obsidian', 'color': const Color(0xFF121212)},
    {'label': 'Butter', 'color': const Color(0xFFFFF8E7)},
    {'label': 'Sage', 'color': const Color(0xFFE8F5E9)},
    {'label': 'Mist', 'color': const Color(0xFFE3F2FD)},
    {'label': 'Blush', 'color': const Color(0xFFFCE4EC)},
    {'label': 'Sand', 'color': const Color(0xFFF5F0E8)},
  ];

  // ── رەنگەکانی تێکست ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _textColors = [
    {'label': 'Ink', 'color': const Color(0xFF1A1A1A)},
    {'label': 'Charcoal', 'color': const Color(0xFF2C2C2C)},
    {'label': 'Stone', 'color': const Color(0xFF5C5C5C)},
    {'label': 'Snow', 'color': const Color(0xFFFFFFFF)},
    {'label': 'Cream', 'color': const Color(0xFFF5F0E8)},
    {'label': 'Gold', 'color': const Color(0xFFD4AF37)},
    {'label': 'Sage', 'color': const Color(0xFF7CB98A)},
    {'label': 'Sky', 'color': const Color(0xFF5DADE2)},
    {'label': 'Rose', 'color': const Color(0xFFE8A0BF)},
    {'label': 'Amber', 'color': const Color(0xFFE59866)},
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

  bool get _isDark => _bgColor.computeLuminance() < 0.5;
  Color get _fg => _isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get _sub => _isDark ? Colors.white54 : const Color(0xFF8A8A8A);
  Color get _card => _isDark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.black.withValues(alpha: 0.04);
  Color get _border => _isDark
      ? Colors.white.withValues(alpha: 0.1)
      : Colors.black.withValues(alpha: 0.08);

  @override
  void initState() {
    super.initState();
    _isPro = PurchaseService.instance.isProUser;
    PurchaseService.instance.addListener(_onProChanged);
    _bgColor = widget.bgColor;
    _fontFamily = widget.fontFamily;
    _dailyQuoteTime = widget.dailyQuoteTime;
    _fontSize = 15.0;
    _textColor = widget.bgColor.computeLuminance() < 0.5
        ? Colors.white
        : const Color(0xFF1A1A1A);
  }

  void _onProChanged() {
    if (mounted) setState(() => _isPro = PurchaseService.instance.isProUser);
  }

  @override
  void dispose() {
    PurchaseService.instance.removeListener(_onProChanged);
    super.dispose();
  }

  void _showUpgrade() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradeSheet(
        onPurchase: () async {
          Navigator.pop(context);
          await PurchaseService.instance.buyYearlyPro();
        },
        onRestore: () async {
          Navigator.pop(context);
          await PurchaseService.instance.restorePurchases();
        },
      ),
    );
  }

  void _showUpgradeMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Upgrade to Pro to unlock this feature"),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "Upgrade",
          textColor: Colors.white,
          onPressed: _showUpgrade,
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final parts = _dailyQuoteTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _dailyQuoteTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _save() {
    widget.onSettingsChanged(_bgColor, _fontFamily, _dailyQuoteTime);
    Navigator.pop(context);
  }

  Widget _buildLockedFeature(String feature, String description) {
    return GestureDetector(
      onTap: _showUpgradeMessage,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_rounded, color: _sub, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "$description — Only for Pro",
                style: TextStyle(color: _sub, fontSize: 13),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Upgrade",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: _fg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Settings",
          style: TextStyle(
            color: _fg,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: _fg, size: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _save,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _fg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Save",
                  style: TextStyle(
                    color: _bgColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── پیش‌دەرکەوتنی لایڤ ──────────────────────────────────────────────
          _buildLivePreview(),
          const SizedBox(height: 28),

          // ── رەنگی باکگراوند ──────────────────────────────────────────────────
          _buildSectionHeader(Icons.palette_outlined, "App Theme"),
          const SizedBox(height: 14),
          _buildThemeGrid(),
          const SizedBox(height: 28),

          // ── رەنگی تێکست ─────────────────────────────────────────────────────
          _buildSectionHeader(Icons.text_fields_rounded, "Text Color"),
          const SizedBox(height: 14),
          _buildTextColorGrid(),
          const SizedBox(height: 28),

          // ── قەبارەی تێکست ───────────────────────────────────────────────────
          _buildSectionHeader(Icons.format_size_rounded, "Text Size"),
          const SizedBox(height: 14),
          _buildFontSizeSlider(),
          const SizedBox(height: 28),

          // ── شێوازی فۆنت ─────────────────────────────────────────────────────
          _buildSectionHeader(Icons.font_download_outlined, "Font Style"),
          const SizedBox(height: 14),
          _buildFontPicker(),
          const SizedBox(height: 28),

          // ── کاتی وتەی ڕۆژانە ─────────────────────────────────────────────────
          _buildSectionHeader(Icons.schedule_rounded, "Daily Quote Time"),
          const SizedBox(height: 14),
          _buildTimePicker(),
          const SizedBox(height: 28),

          // ── ئەپگرەید ─────────────────────────────────────────────────────────
          _buildSectionHeader(Icons.workspace_premium_rounded, "Upgrade"),
          const SizedBox(height: 14),
          _buildUpgradeCard(),
          const SizedBox(height: 28),

          // ── ئەباوت ───────────────────────────────────────────────────────────
          _buildSectionHeader(Icons.info_outline_rounded, "About"),
          const SizedBox(height: 14),
          _buildAboutCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── پیش‌دەرکەوتنی لایڤ ──────────────────────────────────────────────────────
  Widget _buildLivePreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, color: _fg.withValues(alpha: 0.5), size: 22),
          const SizedBox(height: 10),
          Text(
            "Preview",
            style: TextStyle(
              color: _textColor,
              fontSize: _fontSize,
              fontStyle: FontStyle.italic,
              fontFamily: _fontFamily == 'System' ? null : _fontFamily,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "— Wisdom Gates",
            style: TextStyle(
              color: _textColor.withValues(alpha: 0.6),
              fontSize: _fontSize - 3,
              fontFamily: _fontFamily == 'System' ? null : _fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // ── سەردێری بەش ─────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _sub, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _sub,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── گرید رەنگی تیم ──────────────────────────────────────────────────────────
  Widget _buildThemeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: _themes.length,
      itemBuilder: (context, i) {
        final theme = _themes[i];
        final color = theme['color'] as Color;
        final isSelected = _bgColor == color;
        final isLocked = !_isPro && i >= 3;
        return GestureDetector(
          onTap: () {
            if (isLocked) {
              _showUpgradeMessage();
              return;
            }
            setState(() {
              _bgColor = color;
              _textColor = color.computeLuminance() < 0.5
                  ? Colors.white
                  : const Color(0xFF1A1A1A);
            });
          },
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 38 : 34,
                    height: isSelected ? 38 : 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _fg : _border,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8)
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? Icon(Icons.check_rounded,
                            size: 16,
                            color: color.computeLuminance() < 0.5
                                ? Colors.white
                                : Colors.black)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme['label'] as String,
                    style: TextStyle(fontSize: 9, color: _sub),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isLocked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.lock_rounded, size: 12, color: _sub),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── گرید رەنگی تێکست ────────────────────────────────────────────────────────
  Widget _buildTextColorGrid() {
    if (!_isPro) {
      return _buildLockedFeature("Text Color", "Change the text color");
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: _textColors.length,
      itemBuilder: (context, i) {
        final item = _textColors[i];
        final color = item['color'] as Color;
        final isSelected = _textColor == color;
        return GestureDetector(
          onTap: () => setState(() => _textColor = color),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 46 : 42,
                height: isSelected ? 46 : 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _fg : _border,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8)
                        ]
                      : [],
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded,
                        size: 18,
                        color: color.computeLuminance() < 0.5
                            ? Colors.white
                            : Colors.black)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                item['label'] as String,
                style: TextStyle(fontSize: 10, color: _sub),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── سلایدەری قەبارەی تێکست ──────────────────────────────────────────────────
  Widget _buildFontSizeSlider() {
    if (!_isPro) {
      return _buildLockedFeature("Text Size", "Adjust the text size");
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Small", style: TextStyle(fontSize: 11, color: _sub)),
              Text(
                "${_fontSize.round()} px",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _fg,
                ),
              ),
              Text("Large", style: TextStyle(fontSize: 11, color: _sub)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _fg,
              inactiveTrackColor: _fg.withValues(alpha: 0.15),
              thumbColor: _fg,
              overlayColor: _fg.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 3,
            ),
            child: Slider(
              value: _fontSize,
              min: 11,
              max: 24,
              divisions: 13,
              onChanged: (v) => setState(() => _fontSize = v),
            ),
          ),
        ],
      ),
    );
  }

  // ── فۆنت ─────────────────────────────────────────────────────────────────────
  Widget _buildFontPicker() {
    return Column(
      children: _fonts.asMap().entries.map((entry) {
        final index = entry.key;
        final font = entry.value;
        final isSelected = _fontFamily == font;
        final isLocked = !_isPro && index >= 3;
        return GestureDetector(
          onTap: () {
            if (isLocked) {
              _showUpgradeMessage();
              return;
            }
            setState(() => _fontFamily = font);
          },
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? _fg.withValues(alpha: 0.1) : _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _fg.withValues(alpha: 0.4) : _border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _fg : _sub,
                          width: isSelected ? 2 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _fg,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "The quick brown fox — $font",
                        style: TextStyle(
                          fontFamily: font == 'System' ? null : font,
                          color: _fg,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Icon(Icons.lock_rounded, size: 14, color: _sub),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── کاتی وتە ─────────────────────────────────────────────────────────────────
  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _fg.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.schedule_rounded, color: _fg, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Daily Quote",
                      style: TextStyle(fontSize: 12, color: _sub)),
                  const SizedBox(height: 2),
                  Text(
                    _dailyQuoteTime,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _fg,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _sub),
          ],
        ),
      ),
    );
  }

  // ── ئەپگرەید ─────────────────────────────────────────────────────────────────
  Widget _buildUpgradeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF2D1B69), const Color(0xFF11998E)]
              : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: Colors.amber, size: 26),
              SizedBox(width: 10),
              Text(
                "Wisdom Gates Pro",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            "✨ Unlimited themes & fonts",
            "🔔 Advanced reminders",
            "📖 Full quote library",
            "🚫 Ad-free experience",
          ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(f,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await PurchaseService.instance.buyYearlyPro();
                if (!result && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Purchase failed, please try again."),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF764BA2),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Upgrade Now",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ئەباوت ────────────────────────────────────────────────────────────────────
  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _aboutRow(Icons.apps_rounded, "App Name", "Wisdom Gates"),
          _divider(),
          _aboutRow(Icons.tag_rounded, "Version", "1.0.0"),
          _divider(),
          _aboutRow(Icons.code_rounded, "Developer", "Daryan"),
          _divider(),
          _aboutRow(Icons.star_outline_rounded, "Rate the App", ""),
          _divider(),
          _aboutRow(Icons.privacy_tip_outlined, "Privacy Policy", ""),
          _divider(),
          _aboutRow(Icons.mail_outline_rounded, "Contact", ""),
        ],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _sub, size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(color: _fg, fontSize: 14)),
            ),
            if (value.isNotEmpty)
              Text(value, style: TextStyle(color: _sub, fontSize: 13))
            else
              Icon(Icons.chevron_right_rounded, color: _sub, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: _border, indent: 16, endIndent: 16);
}
