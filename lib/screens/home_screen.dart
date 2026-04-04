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
import '../widgets/task_panel.dart';
import '../widgets/quote_edit_dialog.dart';

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

  // Active tab: today, week, month, year
  String _activeTab = 'today';

  // Tasks per category
  List<Task> _todayTasks = [];
  List<Task> _weekTasks = [];
  List<Task> _monthTasks = [];
  List<Task> _yearTasks = [];

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0');
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkFirstLaunch();
    _scheduleDailyQuoteIfNeeded();
    _loadDailyQuote();
    _loadTasks();
    _startClock();
  }

  @override
  void dispose() {
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
    final today = await _taskService.getTasksForCategory('today');
    final week = await _taskService.getTasksForCategory('week');
    final month = await _taskService.getTasksForCategory('month');
    final year = await _taskService.getTasksForCategory('year');
    if (mounted) {
      setState(() {
        _todayTasks = today;
        _weekTasks = week;
        _monthTasks = month;
        _yearTasks = year;
      });
    }
  }

  Future<void> _checkFirstLaunch() async {
    final hasShown = await _storage.getFirstLaunchShown();
    if (!hasShown) {
      if (!mounted) return;
      _showPermissionDialog();
      await _storage.setFirstLaunchShown(true);
    }
  }

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
          "💾 Storage — Save images\n"
          "⏰ Alarms — Reminders\n\n"
          "Please allow to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestAllPermissions();
            },
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    await Permission.notification.request();
    await Permission.storage.request();
    await Permission.scheduleExactAlarm.request();
  }

  Future<bool> requestNotificationForNote() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return true;
  }

  Future<bool> requestAlarmForReminder() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied) {
      final result = await Permission.scheduleExactAlarm.request();
      return result.isGranted;
    }
    return true;
  }

  Future<bool> requestStorageForImage() async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    return true;
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

  List<Task> get _activeTasks {
    switch (_activeTab) {
      case 'today':
        return _todayTasks;
      case 'week':
        return _weekTasks;
      case 'month':
        return _monthTasks;
      case 'year':
        return _yearTasks;
      default:
        return _todayTasks;
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
            _buildTabBar(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildClock(),
                    _buildQuoteSection(),
                    const SizedBox(height: 16),
                    _buildTaskPanel(),
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
          // Settings icon - left
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
          // App name - center
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      color: _textColors.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Wisdom Gates",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textColors,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // App icon placeholder - right
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _textColors.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(Icons.wb_sunny_outlined,
                color: _textColors.withValues(alpha: 0.7), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
      ('year', 'This Year'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textColors.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = _activeTab == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? _textColors.withValues(alpha: 0.9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? _bgColor : _subTextColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$_weekdayName, ${_now.day} $_monthName ${_now.year}",
            style: TextStyle(
              fontSize: 14,
              color: _subTextColor,
              letterSpacing: 0.5,
            ),
          ),
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
            bgColor: _bgColor,
            fontFamily: _fontFamily,
            onSave: (updatedQuote, newBg, newFont) async {
              setState(() {
                _selectedQuote = updatedQuote;
                _bgColor = newBg;
                _fontFamily = newFont;
              });
              await _storage.saveBackgroundColor(_colorToHex(newBg));
              await _storage.saveFontFamily(newFont);
            },
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
                color: _textColors,
                height: 1.5,
                fontFamily: _fontFamily == 'System' ? null : _fontFamily,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "— ${_selectedQuote!.author}",
                  style: TextStyle(fontSize: 12, color: _subTextColor),
                ),
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

  Widget _buildTaskPanel() {
    return TaskPanel(
      category: _activeTab,
      tasks: _activeTasks,
      bgColor: _bgColor,
      textColor: _textColors,
      cardColor: _cardColor,
      subTextColor: _subTextColor,
      onTasksChanged: () => _loadTasks(),
      onRequestAlarm: requestAlarmForReminder,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
          top: BorderSide(color: _textColors.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
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
          _navButton(Icons.format_quote_outlined, "Quotes", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuotesScreen(onQuoteSelected: (q) {
                  setState(() => _selectedQuote = q);
                }),
              ),
            );
          }),
          _navButton(Icons.alarm_outlined, "Reminders", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RemindersScreen(
                  onRequestAlarm: requestAlarmForReminder,
                ),
              ),
            );
          }),
          _navButton(Icons.today_outlined, "Today", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TodayHistoryScreen(),
              ),
            );
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
}

// ── Clock Painter ──────────────────────────────────────────────────────────────
class ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final int second;
  final Color textColor;
  final bool isDark;

  const ClockPainter({
    required this.hour,
    required this.minute,
    required this.second,
    required this.textColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Face
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = textColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Hour ticks
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final outer = Offset(
        center.dx + (radius - 8) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 8) * math.sin(angle - math.pi / 2),
      );
      final inner = Offset(
        center.dx + (radius - 16) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 16) * math.sin(angle - math.pi / 2),
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
      final x = center.dx + (radius - 30) * math.cos(angle - math.pi / 2);
      final y = center.dy + (radius - 30) * math.sin(angle - math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // Hour hand
    final hourAngle = ((hour * 30) + (minute * 0.5) - 90) * math.pi / 180;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius - 55) * math.cos(hourAngle),
        center.dy + (radius - 55) * math.sin(hourAngle),
      ),
      Paint()
        ..color = textColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Minute hand
    final minAngle = (minute * 6 - 90) * math.pi / 180;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius - 35) * math.cos(minAngle),
        center.dy + (radius - 35) * math.sin(minAngle),
      ),
      Paint()
        ..color = textColor.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Second hand
    final secAngle = (second * 6 - 90) * math.pi / 180;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius - 25) * math.cos(secAngle),
        center.dy + (radius - 25) * math.sin(secAngle),
      ),
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(center, 5, Paint()..color = textColor);
    canvas.drawCircle(center, 3, Paint()..color = Colors.redAccent);
  }

  @override
  bool shouldRepaint(covariant ClockPainter old) =>
      old.second != second || old.minute != minute || old.hour != hour;
}
