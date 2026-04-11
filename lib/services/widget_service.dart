import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// ئەم سێرڤیسە داتای ویدجێتەکە نوێ دەکاتەوە
/// هەر جارێک داتاکە گۆڕا (تاسک زیادکرا، نۆت نووسرا، هتد)
/// پێویستە بانگی بکەیت
class WidgetService {
  static const _channel = MethodChannel('com.example.wisdom_app/widget');

  /// نوێکردنەوەی ویدجێت لە داتای ئێستا
  static Future<void> updateWidget() async {
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      // ئەگەر ویدجێت نەبوو یان کێشەیەک هەبوو، گرنگ نییە
      debugPrint('Widget update skipped: $e');
    }
  }

  /// هەڵگرتنی وتەی ئەمرۆ بۆ ویدجێت
  static Future<void> saveDailyQuoteForWidget({
    required String text,
    required String author,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'daily_quote',
      json.encode({'text': text, 'author': author}),
    );
    await updateWidget();
  }
}
