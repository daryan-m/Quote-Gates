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
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_quote,
            size: 60,
            color: textColor.withOpacity(0.4), // color: زیادکرا
          ),
          const SizedBox(height: 24),
          Text(
            quote,
            style: TextStyle(
              fontSize: 26,
              fontFamily: fontFamily == 'System' ? null : fontFamily,
              fontStyle: FontStyle.italic,
              height: 1.4,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            width: 60,
            height: 2,
            color: textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "— $author —",
            style: TextStyle(
              fontSize: 18,
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
