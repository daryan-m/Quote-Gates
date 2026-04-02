// خزمەتگوزاری هەڵگرتنی داتاکان (SharedPreferences)
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _dailyQuoteTimeKey = 'daily_quote_time';
  static const String _lastQuoteIndexKey = 'last_quote_index';
  static const String _backgroundColorKey = 'background_color';
  static const String _fontFamilyKey = 'font_family';
  static const String _isPremiumKey = 'is_premium';

  // کاتی وتەی ڕۆژانە هەڵدەگرێت
  Future<void> saveDailyQuoteTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyQuoteTimeKey, time);
  }

  // کاتی وتەی ڕۆژانە دەهێنێتەوە
  Future<String?> getDailyQuoteTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dailyQuoteTimeKey);
  }

  // ئیندێکسی دوایین وتە هەڵدەگرێت
  Future<void> saveLastQuoteIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastQuoteIndexKey, index);
  }

  // ئیندێکسی دوایین وتە دەهێنێتەوە
  Future<int> getLastQuoteIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastQuoteIndexKey) ?? 0;
  }

  // ڕەنگی پشت‌ڕوو هەڵدەگرێت
  Future<void> saveBackgroundColor(String colorHex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundColorKey, colorHex);
  }

  // ڕەنگی پشت‌ڕوو دەهێنێتەوە
  Future<String> getBackgroundColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundColorKey) ?? '#FFFFFF';
  }

  // فۆنت هەڵدەگرێت
  Future<void> saveFontFamily(String font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, font);
  }

  // فۆنت دەهێنێتەوە
  Future<String> getFontFamily() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fontFamilyKey) ?? 'System';
  }

  // ستەیتی پریمیوم هەڵدەگرێت
  Future<void> setPremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, isPremium);
  }

  // ستەیتی پریمیوم دەهێنێتەوە
  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPremiumKey) ?? false;
  }
}