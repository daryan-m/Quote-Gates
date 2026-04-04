import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/storage_service.dart';
import '../services/quote_loader.dart';
import '../services/notification_service.dart';
import '../models/quote.dart';
import 'quotes_screen.dart';
import 'notes_screen.dart';
import 'reminders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  Quote? _selectedQuote;
  String _selectedTime = "08:00";
  Color _bgColor = Colors.white;

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0');
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scheduleDailyQuoteIfNeeded();
  }

  Future<void> _loadSettings() async {
    final colorHex = await _storage.getBackgroundColor();
    final time = await _storage.getDailyQuoteTime();

    setState(() {
      _bgColor = Color(int.parse(colorHex, radix: 16));
      if (time != null) _selectedTime = time;
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
    final TimeOfDay? picked = await showTimePicker(
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
        const SnackBar(content: Text("Daily quote time set")),
      );
    }
  }

  Future<void> _changeBackgroundColor() async {
    final Color? newColor = await showDialog(
      context: context,
      builder: (_) => const SimpleDialog(
        title: Text("Choose Background Color"),
        children: [
          SimpleDialogOption(child: Text("White")),
          SimpleDialogOption(child: Text("Black")),
          SimpleDialogOption(child: Text("Light Blue")),
        ],
      ),
    );
    if (!mounted) return;
    if (newColor != null) {
      setState(() => _bgColor = newColor);
      await _storage.saveBackgroundColor(_colorToHex(newColor));
    }
  }

  void _selectQuote(Quote quote) {
    setState(() {
      _selectedQuote = quote;
    });
  }

  Widget _buildAnalogClock() {
    final now = DateTime.now();
    final hour = now.hour % 12;
    final minute = now.minute;
    final second = now.second;
    final hourAngle = (hour * 30) + (minute * 0.5);
    final minuteAngle = minute * 6.0;
    final secondAngle = second * 6.0;

    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: ClockPainter(
          hourAngle: hourAngle,
          minuteAngle: minuteAngle,
          secondAngle: secondAngle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    final weekday = weekdays[now.weekday - 1];
    final date = "${now.day} ${_monthName(now.month)} ${now.year}";

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
                    IconButton(
                      icon: const Icon(Icons.palette),
                      onPressed: _changeBackgroundColor,
                    ),
                    const Text(
                      "Wisdom Gates",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                        IconButton(
                          icon: const Icon(Icons.timer),
                          onPressed: _setDailyQuoteTime,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnalogClock(),
                    const SizedBox(height: 12),
                    Text(
                      weekday,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                          fontSize: 14, color: Colors.blueGrey.shade400),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedQuote != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const Icon(Icons.format_quote,
                                size: 30, color: Colors.blueGrey),
                            const SizedBox(height: 8),
                            Text(
                              _selectedQuote!.text,
                              style: const TextStyle(
                                  fontSize: 16, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "— ${_selectedQuote!.author}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                  ],
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
                          builder: (_) =>
                              QuotesScreen(onQuoteSelected: _selectQuote),
                        ),
                      );
                    }),
                    _navButton(Icons.note_add, "Notes", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotesScreen()),
                      );
                    }),
                    _navButton(Icons.alarm, "Reminders", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RemindersScreen()),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
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

class ClockPainter extends CustomPainter {
  final double hourAngle;
  final double minuteAngle;
  final double secondAngle;

  const ClockPainter({
    required this.hourAngle,
    required this.minuteAngle,
    required this.secondAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle = Paint()
      ..color = Colors.blueGrey.shade50
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paintCircle);

    final borderPaint = Paint()
      ..color = Colors.blueGrey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    const textStyle = TextStyle(
        fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey);
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final x = center.dx + (radius - 30) * math.cos(angle - math.pi / 2);
      final y = center.dy + (radius - 30) * math.sin(angle - math.pi / 2);
      final textSpan = TextSpan(text: i.toString(), style: textStyle);
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 7, y - 7));
    }

    final hourHand = Paint()
      ..color = Colors.black87
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final minuteHand = Paint()
      ..color = Colors.black54
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final secondHand = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final hourX =
        center.dx + (radius - 55) * math.cos((hourAngle - 90) * math.pi / 180);
    final hourY =
        center.dy + (radius - 55) * math.sin((hourAngle - 90) * math.pi / 180);
    canvas.drawLine(center, Offset(hourX, hourY), hourHand);

    final minuteX = center.dx +
        (radius - 35) * math.cos((minuteAngle - 90) * math.pi / 180);
    final minuteY = center.dy +
        (radius - 35) * math.sin((minuteAngle - 90) * math.pi / 180);
    canvas.drawLine(center, Offset(minuteX, minuteY), minuteHand);

    final secondX = center.dx +
        (radius - 25) * math.cos((secondAngle - 90) * math.pi / 180);
    final secondY = center.dy +
        (radius - 25) * math.sin((secondAngle - 90) * math.pi / 180);
    canvas.drawLine(center, Offset(secondX, secondY), secondHand);

    canvas.drawCircle(
        center,
        5,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) => true;
}
