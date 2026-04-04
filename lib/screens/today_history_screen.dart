import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TodayHistoryScreen extends StatefulWidget {
  const TodayHistoryScreen({super.key});

  @override
  State<TodayHistoryScreen> createState() => _TodayHistoryScreenState();
}

class _TodayHistoryScreenState extends State<TodayHistoryScreen> {
  // ١. فانکشن بۆ دیاریکردنی ئایکۆن بەپێی جۆری ڕووداوەکە
  String _getIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'history':
        return '🏛️';
      case 'science':
        return '🧪';
      case 'invention':
        return '💡';
      case 'art':
        return '🎨';
      case 'war':
        return '⚔️';
      case 'politics':
        return '⚖️';
      case 'exploration':
        return '🧭';
      case 'disaster':
        return '🌋';
      case 'culture':
        return '🎭';
      case 'religion':
        return '⛪';
      case 'civilization':
        return '🏗️';
      default:
        return '📜';
    }
  }

  // ٢. خوێندنەوەی داتاکان لە JSON
  Future<List<dynamic>> _loadHistoricalEvents() async {
    try {
      final String response =
          await rootBundle.loadString('assets/historical_events.json');
      final data = await json.decode(response);

      final now = DateTime.now();
      final String month = now.month.toString();
      final String day = now.day.toString();

      if (data[month] != null && data[month][day] != null) {
        return data[month][day];
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("On This Day",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("${months[now.month - 1]} ${now.day}",
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loadHistoricalEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
                child: Text("No events found.",
                    style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              // --- ئەوەی پێم وتی لێرەدایە ---
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // پیشاندانی ئایکۆنەکە
                    Text(_getIcon(event['category'] as String?),
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    // پیشاندانی ساڵ و ڕووداوەکە
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${event['year']}",
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(event['event'] as String,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              // --- کۆتایی بەشەکە ---
            },
          );
        },
      ),
    );
  }
}
