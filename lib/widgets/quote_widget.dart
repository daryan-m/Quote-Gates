import 'package:flutter/material.dart';

class QuoteWidget extends StatelessWidget {
  final String quote;
  final String author;
  final Color backgroundColor;
  final String fontFamily;

  const QuoteWidget({
    super.key,
    required this.quote,
    required this.author,
    required this.backgroundColor,
    this.fontFamily = 'System',
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? Colors.white : const Color(0xFF2C2C2C);
    final subTextColor =
        isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.45);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 52,
            color: textColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          Text(
            quote,
            style: TextStyle(
              fontSize: 22,
              fontFamily: fontFamily == 'System' ? null : fontFamily,
              fontStyle: FontStyle.italic,
              height: 1.55,
              color: textColor,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            width: 48,
            height: 1.5,
            decoration: BoxDecoration(
              color: subTextColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "— $author",
            style: TextStyle(
              fontSize: 15,
              color: subTextColor,
              fontFamily: fontFamily == 'System' ? null : fontFamily,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
