// بارکردنی وتەکان لە فایلەکانی JSONەوە
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/quote.dart';

class QuoteLoader {
  static List<Quote> _allQuotes = [];

  // هەموو وتەکان لە هەموو فایلەکانەوە دەخاتە یەک لیست
  static Future<List<Quote>> loadAllQuotes() async {
    if (_allQuotes.isNotEmpty) return _allQuotes;

    final List<Quote> quotes = [];

    // بارکردنی 100 وتە
    quotes.addAll(await _loadQuotesFromAsset('assets/quotes/quotes_100.json'));
    // بارکردنی 200 وتە
    quotes.addAll(await _loadQuotesFromAsset('assets/quotes/quotes_200.json'));
    // بارکردنی 400 وتە
    quotes.addAll(await _loadQuotesFromAsset('assets/quotes/quotes_400.json'));
    // بارکردنی 800 وتە
    quotes.addAll(await _loadQuotesFromAsset('assets/quotes/quotes_800.json'));
    // بارکردنی 1600 وتە
    quotes.addAll(await _loadQuotesFromAsset('assets/quotes/quotes_1600.json'));

    _allQuotes = quotes;
    return quotes;
  }

  // بارکردنی وتەکان لە فایلێکی تایبەت
  static Future<List<Quote>> _loadQuotesFromAsset(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Quote.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // وەرگرتنی وتەیەکی هەڕەمەکی
  static Future<Quote> getRandomQuote() async {
    final quotes = await loadAllQuotes();
    if (quotes.isEmpty) {
      return Quote(
        text: "The only true wisdom is in knowing you know nothing.",
        author: "Socrates",
      );
    }
    final randomIndex = DateTime.now().millisecondsSinceEpoch % quotes.length;
    return quotes[randomIndex];
  }

  // وەرگرتنی وتەی ڕۆژانە (لەسەر بنەمای ڕێکەوت)
  static Future<Quote> getDailyQuote() async {
    final quotes = await loadAllQuotes();
    if (quotes.isEmpty) {
      return Quote(
        text: "The journey of a thousand miles begins with one step.",
        author: "Lao Tzu",
      );
    }
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % quotes.length;
    return quotes[index];
  }
}
