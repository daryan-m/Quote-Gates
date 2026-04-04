import 'package:flutter/material.dart';

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

  final List<Map<String, dynamic>> _bgOptions = [
    {'label': 'Cream', 'color': const Color(0xFFF8F6F0)},
    {'label': 'White', 'color': Colors.white},
    {'label': 'Night', 'color': const Color(0xFF1A1A2E)},
    {'label': 'Navy', 'color': const Color(0xFF16213E)},
    {'label': 'Forest', 'color': const Color(0xFF1B4332)},
    {'label': 'Purple', 'color': const Color(0xFF6B2D8B)},
    {'label': 'Coffee', 'color': const Color(0xFF7B3F00)},
    {'label': 'Black', 'color': const Color(0xFF1A1A1A)},
    {'label': 'Warm', 'color': const Color(0xFFFFF8E7)},
    {'label': 'Mint', 'color': const Color(0xFFE8F5E9)},
    {'label': 'Sky', 'color': const Color(0xFFE3F2FD)},
  ];

  bool get _isDark => _bgColor.computeLuminance() < 0.5;
  Color get _textColors => _isDark ? Colors.white : const Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    _bgColor = widget.bgColor;
    _fontFamily = widget.fontFamily;
    _dailyQuoteTime = widget.dailyQuoteTime;
  }

  Future<void> _pickTime() async {
    final parts = _dailyQuoteTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() {
        _dailyQuoteTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: _textColors,
        elevation: 0,
        title: Text("Settings",
            style: TextStyle(color: _textColors, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSettingsChanged(_bgColor, _fontFamily, _dailyQuoteTime);
              Navigator.pop(context);
            },
            child: Text("Save",
                style:
                    TextStyle(color: _textColors, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // باکگراوند
          _sectionTitle("Theme"),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _bgOptions.map((opt) {
              final color = opt['color'] as Color;
              final isSelected = _bgColor == color;
              return GestureDetector(
                onTap: () => setState(() => _bgColor = color),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(Icons.check,
                              color: color.computeLuminance() < 0.5
                                  ? Colors.white
                                  : Colors.black)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(opt['label'] as String,
                        style: TextStyle(
                            fontSize: 11,
                            color: _textColors.withValues(alpha: 0.7))),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // فۆنت
          _sectionTitle("Font Style"),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: _fontFamily,
            onChanged: (v) => setState(() => _fontFamily = v!),
            child: Column(
              children: ['System', 'Serif', 'Monospace'].map((font) {
                final isSelected = _fontFamily == font;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _textColors.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _textColors.withValues(alpha: 0.3)
                          : _textColors.withValues(alpha: 0.1),
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: font,
                    title: Text(
                      "The quick brown fox — $font",
                      style: TextStyle(
                        fontFamily: font == 'System' ? null : font,
                        color: _textColors,
                        fontSize: 14,
                      ),
                    ),
                    activeColor: _textColors,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // کاتی وتەی ڕۆژانە
          _sectionTitle("Daily Quote Time"),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _textColors.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _textColors.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm, color: _textColors),
                  const SizedBox(width: 12),
                  Text(
                    _dailyQuoteTime,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _textColors,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_outlined,
                      color: _textColors.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _textColors.withValues(alpha: 0.5),
        letterSpacing: 1,
      ),
    );
  }
}
