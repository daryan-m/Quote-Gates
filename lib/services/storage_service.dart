import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _dailyQuoteTimeKey = 'daily_quote_time';
  static const String _lastQuoteIndexKey = 'last_quote_index';
  static const String _backgroundColorKey = 'background_color';
  static const String _fontFamilyKey = 'font_family';
  static const String _isPremiumKey = 'is_premium';
  static const String _firstLaunchKey = 'first_launch_shown';

  // کاتی وتەی ڕۆژانە
  Future<void> saveDailyQuoteTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyQuoteTimeKey, time);
  }

  Future<String?> getDailyQuoteTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dailyQuoteTimeKey);
  }

  // ئیندێکسی دوایین وتە
  Future<void> saveLastQuoteIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastQuoteIndexKey, index);
  }

  Future<int> getLastQuoteIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastQuoteIndexKey) ?? 0;
  }

  // ڕەنگی پشت ڕوو
  Future<void> saveBackgroundColor(String colorHex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundColorKey, colorHex);
  }

  Future<String> getBackgroundColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundColorKey) ?? 'ffffffff';
  }

  // فۆنت
  Future<void> saveFontFamily(String font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, font);
  }

  Future<String> getFontFamily() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fontFamilyKey) ?? 'System';
  }

  // پریمیوم
  Future<void> setPremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, isPremium);
  }

  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPremiumKey) ?? false;
  }

  // یەکەم جار کردنەوە (بۆ ڕێگەپێدان)
  Future<void> setFirstLaunchShown(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, value);
  }

  Future<bool> getFirstLaunchShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? false;
  }

  // لە ناو کلاسی StorageService دا، لە کۆتاییدا
  Future<void> saveQuoteStyle(
      Color bgColor, Color textColor, String font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quote_bg_color', bgColor.toARGB32());
    await prefs.setInt('quote_text_color', textColor.toARGB32());
    await prefs.setString('quote_font', font);
  }

  Future<Color> getSavedQuoteBgColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('quote_bg_color');
    return colorValue != null ? Color(colorValue) : Colors.white;
  }

  Future<Color> getSavedQuoteTextColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('quote_text_color');
    return colorValue != null ? Color(colorValue) : const Color(0xFF2C2C2C);
  }

  Future<String> getSavedQuoteFont() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('quote_font') ?? 'System';
  }
}
