import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/storage_service.dart';
import '../services/quote_loader.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../models/quote.dart';
import '../models/task.dart';
import 'quotes_screen.dart';
import 'notes_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';
import 'today_history_screen.dart';
import 'tasks_screen.dart';
import '../widgets/quote_edit_dialog.dart';
import '../services/purchase_service.dart';
import 'package:wisdom_app/widgets/upgrade_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final TaskService _taskService = TaskService();

  Quote? _selectedQuote;
  String _selectedTime = "08:00";
  Color _bgColor = const Color(0xFFF8F6F0);
  String _fontFamily = 'System';

  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  List<Task> _allTasks = [];

  Color _quoteTextColor = const Color(0xFF2C2C2C);
  String _quoteFontFamily = 'System';

  bool _isPro = false;

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0');
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadQuoteStyle();
    _checkFirstLaunch();
    _scheduleDailyQuoteIfNeeded();
    _loadDailyQuote();
    _loadTasks();
    _startClock();
    _isPro = PurchaseService.instance.isProUser;
    PurchaseService.instance.addListener(_onProChanged);
  }

  void _onProChanged() {
    if (mounted) setState(() => _isPro = PurchaseService.instance.isProUser);
  }

  @override
  void dispose() {
    PurchaseService.instance.removeListener(_onProChanged);
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _loadDailyQuote() async {
    final quote = await QuoteLoader.getDailyQuote();
    if (mounted) setState(() => _selectedQuote = quote);
  }

  Future<void> _loadTasks() async {
    final all = await _taskService.getAllTasks();
    if (mounted) setState(() => _allTasks = all);
  }

  Future<void> _checkFirstLaunch() async {
    final hasShown = await _storage.getFirstLaunchShown();
    if (!hasShown) {
      if (!mounted) return;
      _showPermissionDialog();
      await _storage.setFirstLaunchShown(true);
    }
  }

  // ١. نیشاندانی دیالۆگی ڕێپێدانەکان
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Permissions Required",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "This app needs:\n\n"
          "🔔 Notifications — Daily quotes\n"
          "🖼️ Photos — Save images\n" // گۆڕدرا بۆ وێنە
          "⏰ Alarms — Reminders\n\n"
          "Please allow all to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestAllPermissions();
            },
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }

  // ٢. داواکردنی ڕێپێدانەکان بە شێوەی زنجیرەیی و بەکارهێنانی Photos
  Future<void> _requestAllPermissions() async {
    // داواکردنی نۆتیفیکەیشن
    await Permission.notification.request();

    // داواکردنی ئالارم
    await Permission.scheduleExactAlarm.request();

    if (mounted) {
      setState(() {});
    }
  }

  // --- فانکشنەکانی تاقیکردنەوە بە جیا ---

  Future<bool> requestNotificationForNote() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestAlarmForReminder() async {
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  Future<void> _loadSettings() async {
    final colorHex = await _storage.getBackgroundColor();
    final time = await _storage.getDailyQuoteTime();
    final font = await _storage.getFontFamily();
    if (mounted) {
      setState(() {
        _bgColor = Color(int.parse(colorHex, radix: 16));
        if (time != null) _selectedTime = time;
        _fontFamily = font;
      });
    }
  }

  Future<void> _loadQuoteStyle() async {
    final textColor = await _storage.getSavedQuoteTextColor();
    final font = await _storage.getSavedQuoteFont();
    setState(() {
      _quoteTextColor = textColor;
      _quoteFontFamily = font;
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

  bool get _isDark => _bgColor.computeLuminance() < 0.5;

  Color get _textColors => _isDark ? Colors.white : const Color(0xFF2C2C2C);

  Color get _subTextColor => _isDark ? Colors.white60 : const Color(0xFF8A8A8A);

  Color get _cardColor => _isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.7);

  String get _monthName {
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
    return months[_now.month - 1];
  }

  String get _weekdayName {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[_now.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildClock(),
                    _buildQuoteSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: _textColors),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    bgColor: _bgColor,
                    fontFamily: _fontFamily,
                    dailyQuoteTime: _selectedTime,
                    onSettingsChanged: (color, font, time) async {
                      setState(() {
                        _bgColor = color;
                        _fontFamily = font;
                        _selectedTime = time;
                      });
                      await _storage.saveBackgroundColor(_colorToHex(color));
                      await _storage.saveFontFamily(font);
                      await _storage.saveDailyQuoteTime(time);
                    },
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      color: _textColors.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 8),
                  Text("Wisdom Gates",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textColors,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
          if (!_isPro)
            GestureDetector(
              onTap: _showUpgradeSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "Upgrade",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildClock() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: ClockPainter(
                hour: _now.hour % 12,
                minute: _now.minute,
                second: _now.second,
                textColor: _textColors,
                isDark: _isDark,
                tasks: _allTasks,
                now: _now,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text("$_weekdayName, ${_now.day} $_monthName ${_now.year}",
              style: TextStyle(
                  fontSize: 14, color: _subTextColor, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildQuoteSection() {
    if (_selectedQuote == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => QuoteEditDialog(
            quote: _selectedQuote!,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _textColors.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(Icons.format_quote,
                size: 24, color: _textColors.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              _selectedQuote!.text,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: _quoteTextColor,
                height: 1.5,
                fontFamily:
                    _quoteFontFamily == 'System' ? null : _quoteFontFamily,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("— ${_selectedQuote!.author}",
                    style: TextStyle(fontSize: 12, color: _subTextColor)),
                Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 14, color: _subTextColor),
                    const SizedBox(width: 4),
                    Icon(Icons.share_outlined, size: 14, color: _subTextColor),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        border:
            Border(top: BorderSide(color: _textColors.withValues(alpha: 0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navButton(Icons.task_alt_outlined, "Tasks", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TasksScreen(
                  bgColor: _bgColor,
                  textColor: _textColors,
                  onRequestAlarm: requestAlarmForReminder,
                  onTaskChanged: _loadTasks,
                ),
              ),
            );
          }),
          _navButton(Icons.note_outlined, "Notes", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotesScreen(
                  onRequestNotification: requestNotificationForNote,
                  onRequestAlarm: requestAlarmForReminder,
                ),
              ),
            );
          }),
          _navButton(Icons.alarm_outlined, "Reminders", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RemindersScreen(onRequestAlarm: requestAlarmForReminder),
              ),
            );
          }),
          _navButton(Icons.format_quote_outlined, "Quotes", () {
            if (!_isPro) {
              _showUpgradeSheet();
              return;
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuotesScreen(onQuoteSelected: (q) {
                    setState(() => _selectedQuote = q);
                  }),
                ));
          }),
          _navButton(Icons.today_outlined, "Today", () {
            if (!_isPro) {
              _showUpgradeSheet();
              return;
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TodayHistoryScreen(),
                ));
          }),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: _textColors),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: _subTextColor)),
          ],
        ),
      ),
    );
  }

  void _showUpgradeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradeSheet(
        onPurchase: () async {
          Navigator.pop(context);
          final ok = await PurchaseService.instance.buyYearlyPro();
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text("کڕین سەرکەوتوو نەبوو، دووبارە هەوڵبدەرەوە"),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onRestore: () async {
          Navigator.pop(context);
          await PurchaseService.instance.restorePurchases();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("کڕینەکانت گەڕاندەوە"),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}

// ── Clock Painter ──────────────────────────────────────────────────────────────
class ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final int second;
  final Color textColor;
  final bool isDark;
  final List<Task> tasks;
  final DateTime now;

  const ClockPainter({
    required this.hour,
    required this.minute,
    required this.second,
    required this.textColor,
    required this.isDark,
    required this.tasks,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 4 rings outside the clock (year, month, week, day)
    _drawYearRing(canvas, center, radius);
    _drawMonthRing(canvas, center, radius);
    _drawWeekRing(canvas, center, radius);
    _drawDayRing(canvas, center, radius);

    // Clock face
    canvas.drawCircle(
      center,
      radius - 28,
      Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill,
    );

    // Clock border
    canvas.drawCircle(
      center,
      radius - 28,
      Paint()
        ..color = textColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Hour ticks
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final outer = Offset(
        center.dx + (radius - 32) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 32) * math.sin(angle - math.pi / 2),
      );
      final inner = Offset(
        center.dx + (radius - 40) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 40) * math.sin(angle - math.pi / 2),
      );
      canvas.drawLine(
        outer,
        inner,
        Paint()
          ..color = textColor.withValues(alpha: 0.4)
          ..strokeWidth = i % 3 == 0 ? 2.5 : 1,
      );
    }

    // Numbers
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final x = center.dx + (radius - 48) * math.cos(angle - math.pi / 2);
      final y = center.dy + (radius - 48) * math.sin(angle - math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // Hour hand
    final hourAngle = ((hour * 30) + (minute * 0.5) - 90) * math.pi / 180;
    canvas.drawLine(
      center,
      Offset(center.dx + (radius - 70) * math.cos(hourAngle),
          center.dy + (radius - 70) * math.sin(hourAngle)),
      Paint()
        ..color = textColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Minute hand
    final minAngle = (minute * 6 - 90) * math.pi / 180;
    canvas.drawLine(
      center,
      Offset(center.dx + (radius - 50) * math.cos(minAngle),
          center.dy + (radius - 50) * math.sin(minAngle)),
      Paint()
        ..color = textColor.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Second hand
    final secAngle = (second * 6 - 90) * math.pi / 180;
    canvas.drawLine(
      center,
      Offset(center.dx + (radius - 40) * math.cos(secAngle),
          center.dy + (radius - 40) * math.sin(secAngle)),
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = textColor);
    canvas.drawCircle(center, 2, Paint()..color = Colors.redAccent);
  }

  void _drawYearRing(Canvas canvas, Offset center, double radius) {
    final ringRadius = radius - 8;
    canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = textColor.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    for (var task in tasks) {
      final taskTime = task.scheduledTime;
      if (taskTime == null) continue;
      final autoCat = _getAutoCategory(taskTime);
      if (autoCat != 'year') continue;
      final monthAngle = ((taskTime.month - 1) * (360 / 12)) - 90;
      _drawTaskArc(canvas, center, ringRadius, monthAngle, monthAngle + 5,
          Colors.purple);
    }
  }

  void _drawMonthRing(Canvas canvas, Offset center, double radius) {
    final ringRadius = radius - 16;
    canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = textColor.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    for (int i = 0; i < daysInMonth; i++) {
      final startAngle = (i * (360 / daysInMonth)) - 90;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle * math.pi / 180,
        (360 / daysInMonth) * math.pi / 180,
        false,
        Paint()
          ..color = textColor.withValues(alpha: 0.05)
          ..strokeWidth = 1,
      );
    }

    for (var task in tasks) {
      final taskTime = task.scheduledTime;
      if (taskTime == null) continue;
      final autoCat = _getAutoCategory(taskTime);
      if (autoCat != 'month') continue;
      final daysInMonthNow = DateTime(now.year, now.month + 1, 0).day;
      final dayAngle = ((taskTime.day - 1) * (360 / daysInMonthNow)) - 90;
      _drawTaskArc(
          canvas, center, ringRadius, dayAngle, dayAngle + 3, Colors.blue);
    }
  }

  void _drawWeekRing(Canvas canvas, Offset center, double radius) {
    final ringRadius = radius - 24;
    canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = textColor.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    for (int i = 0; i < 7; i++) {
      final startAngle = (i * (360 / 7)) - 90;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle * math.pi / 180,
        (360 / 7) * math.pi / 180,
        false,
        Paint()
          ..color = textColor.withValues(alpha: 0.08)
          ..strokeWidth = 1,
      );
    }

    for (var task in tasks) {
      final taskTime = task.scheduledTime;
      if (taskTime == null) continue;
      final autoCat = _getAutoCategory(taskTime);
      if (autoCat != 'week') continue;
      final diffDays = now.difference(taskTime).inDays.abs();
      if (diffDays > 7) continue;
      final weekdayAngle = ((taskTime.weekday - 1) * (360 / 7)) - 90;
      final hourAngle =
          ((taskTime.hour * 60 + taskTime.minute) * (360 / (24 * 60))) - 90;
      final totalAngle = weekdayAngle + (hourAngle / 7);
      _drawTaskArc(
          canvas, center, ringRadius, totalAngle, totalAngle + 2, Colors.green);
    }
  }

  void _drawDayRing(Canvas canvas, Offset center, double radius) {
    final ringRadius = radius - 32;
    canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = textColor.withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    for (int i = 0; i < 24; i++) {
      final startAngle = (i * 15) - 90;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle * math.pi / 180,
        15 * math.pi / 180,
        false,
        Paint()
          ..color = textColor.withValues(alpha: 0.06)
          ..strokeWidth = 1,
      );
    }

    for (var task in tasks) {
      final taskTime = task.scheduledTime;
      if (taskTime == null) continue;
      final autoCat = _getAutoCategory(taskTime);
      if (autoCat != 'today') continue;
      final diffDays = now.difference(taskTime).inDays.abs();
      if (diffDays > 1) continue;
      final hourAngle =
          ((taskTime.hour * 60 + taskTime.minute) * (360 / (24 * 60))) - 90;
      _drawTaskArc(
          canvas, center, ringRadius, hourAngle, hourAngle + 4, Colors.orange);
    }
  }

  void _drawTaskArc(Canvas canvas, Offset center, double radius,
      double startAngleDeg, double endAngleDeg, Color color) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngleDeg * math.pi / 180,
      (endAngleDeg - startAngleDeg) * math.pi / 180,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  String _getAutoCategory(DateTime time) {
    final diff = time.difference(DateTime.now());
    if (diff.inDays < 1) return 'today';
    if (diff.inDays < 7) return 'week';
    if (diff.inDays < 30) return 'month';
    return 'year';
  }

  @override
  bool shouldRepaint(covariant ClockPainter old) {
    return old.second != second ||
        old.minute != minute ||
        old.hour != hour ||
        old.now.day != now.day ||
        old.now.month != now.month ||
        old.now.year != now.year;
  }
}
