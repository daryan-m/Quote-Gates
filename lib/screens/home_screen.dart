import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/quote_loader.dart';
import '../services/notification_service.dart';
import '../widgets/quote_widget.dart';
import 'quotes_screen.dart';
import 'notes_screen.dart';
import 'reminders_screen.dart';
import '../utils/image_share.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  String _todayQuote = "Loading wisdom...";
  String _todayAuthor = "";
  String _selectedTime = "08:00";
  Color _bgColor = Colors.white;
  String _fontFamily = 'System';
  bool _isPremium = false;
  final GlobalKey _quoteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDailyQuote();
    _scheduleDailyQuoteIfNeeded();
  }

  Future<void> _loadSettings() async {
    final colorHex = await _storage.getBackgroundColor();
    final font = await _storage.getFontFamily();
    final premium = await _storage.isPremium();
    final time = await _storage.getDailyQuoteTime();

    setState(() {
      _bgColor = Color(int.parse(colorHex));
      _fontFamily = font;
      _isPremium = premium;
      if (time != null) _selectedTime = time;
    });
  }

  Future<void> _loadDailyQuote() async {
    final quote = await QuoteLoader.getDailyQuote();
    setState(() {
      _todayQuote = quote.text;
      _todayAuthor = quote.author;
    });
  }

  Future<void> _scheduleDailyQuoteIfNeeded() async {
    final time = await _storage.getDailyQuoteTime();
    if (time != null) {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final quote = await QuoteLoader.getDailyQuote();

      await NotificationService.scheduleDailyQuote(
        hour: hour,
        minute: minute,
        quote: quote.text,
        author: quote.author,
      );
    }
  }

  Future<void> _setDailyQuoteTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );

    if (!mounted) return;

    if (picked != null) {
      final timeString =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      await _storage.saveDailyQuoteTime(timeString);
      setState(() => _selectedTime = timeString);

      final quote = await QuoteLoader.getDailyQuote();
      await NotificationService.scheduleDailyQuote(
        hour: picked.hour,
        minute: picked.minute,
        quote: quote.text,
        author: quote.author,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Daily quote time set to $timeString")),
      );
    }
  }

  Future<void> _changeBackgroundColor() async {
    Color? newColor = await showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Choose Background Color"),
        children: [
          SimpleDialogOption(
            child: const Text("White"),
            onPressed: () => Navigator.pop(context, Colors.white),
          ),
          SimpleDialogOption(
            child: const Text("Black"),
            onPressed: () => Navigator.pop(context, Colors.black87),
          ),
          SimpleDialogOption(
            child: const Text("Light Blue"),
            onPressed: () => Navigator.pop(context, Colors.lightBlue.shade50),
          ),
          SimpleDialogOption(
            child: const Text("Light Green"),
            onPressed: () => Navigator.pop(context, Colors.lightGreen.shade50),
          ),
          SimpleDialogOption(
            child: const Text("Light Yellow"),
            onPressed: () => Navigator.pop(context, Colors.amber.shade50),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (newColor != null) {
      setState(() => _bgColor = newColor);
      await _storage.saveBackgroundColor(newColor.toARGB32().toRadixString(16));
    }
  }

  Future<void> _changeFont() async {
    String? newFont = await showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Choose Font"),
        children: [
          SimpleDialogOption(
            child: const Text("System Default"),
            onPressed: () => Navigator.pop(context, "System"),
          ),
          SimpleDialogOption(
            child: const Text("Serif"),
            onPressed: () => Navigator.pop(context, "Serif"),
          ),
          SimpleDialogOption(
            child: const Text("Monospace"),
            onPressed: () => Navigator.pop(context, "Monospace"),
          ),
        ],
      ),
    );

    if (!mounted || newFont == null) {
      return; // چاوەڕوانی cancel یان unmounted widget
    }

    setState(() => _fontFamily = newFont);
    await _storage.saveFontFamily(newFont);
  }

  Future<void> _shareQuoteAsImage() async {
    await ImageShare.captureAndShare(_quoteKey, _todayQuote, _todayAuthor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: _bgColor),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.palette),
                          onPressed: _changeBackgroundColor,
                          tooltip: "Change Background",
                        ),
                        IconButton(
                          icon: const Icon(Icons.font_download),
                          onPressed: _changeFont,
                          tooltip: "Change Font",
                        ),
                      ],
                    ),
                    const Text(
                      "Wisdom",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedTime,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!_isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "FREE",
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.timer),
                          onPressed: _setDailyQuoteTime,
                          tooltip: "Set Daily Quote Time",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RepaintBoundary(
                  key: _quoteKey,
                  child: QuoteWidget(
                    quote: _todayQuote,
                    author: _todayAuthor,
                    backgroundColor: _bgColor,
                    fontFamily: _fontFamily,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navButton(Icons.format_quote, "Quotes", () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QuotesScreen()));
                    }),
                    _navButton(Icons.note_add, "Notes", () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotesScreen()));
                    }),
                    _navButton(Icons.alarm, "Reminders", () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RemindersScreen()));
                    }),
                    _navButton(Icons.share, "Share", _shareQuoteAsImage),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.blueGrey),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
