import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  final Future<bool> Function()? onRequestAlarm;

  const RemindersScreen({super.key, this.onRequestAlarm});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> _reminders = [];
  String _filter = 'all'; // all, today, upcoming, done

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // ── بارکردن و هەڵگرتن ───────────────────────────────────────────────────
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_reminders');
    if (raw != null && mounted) {
      setState(
          () => _reminders = List<Map<String, dynamic>>.from(json.decode(raw)));
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_reminders', json.encode(_reminders));
  }

  // ── فیلتەر ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredReminders {
    final now = DateTime.now();
    return _reminders.where((r) {
      final dt = DateTime.parse(r['dateTime']);
      final isDone = r['isDone'] == true;
      switch (_filter) {
        case 'today':
          return dt.day == now.day &&
              dt.month == now.month &&
              dt.year == now.year &&
              !isDone;
        case 'upcoming':
          return dt.isAfter(now) && !isDone;
        case 'done':
          return isDone;
        default:
          return !isDone;
      }
    }).toList()
      ..sort((a, b) => DateTime.parse(a['dateTime'])
          .compareTo(DateTime.parse(b['dateTime'])));
  }

  // ── کردنەوەی دیالۆگی ریمایندەر ──────────────────────────────────────────
  void _openReminderDialog({int? index}) {
    final isEditing = index != null;
    final reminder =
        isEditing ? Map<String, dynamic>.from(_reminders[index]) : null;

    final titleCtrl = TextEditingController(text: reminder?['title'] ?? '');
    final noteCtrl = TextEditingController(text: reminder?['note'] ?? '');

    DateTime selectedDate = reminder != null
        ? DateTime.parse(reminder['dateTime'])
        : DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay(
      hour: selectedDate.hour,
      minute: selectedDate.minute,
    );

    String repeatType = reminder?['repeatType'] ?? 'none';
    List<String> selectedWeekdays =
        List<String>.from(reminder?['weekdays'] ?? []);

    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final repeatOptions = [
      ('none', 'No repeat', Icons.block_rounded),
      ('daily', 'Daily', Icons.repeat_one_rounded),
      ('weekly', 'Weekly', Icons.repeat_rounded),
      ('monthly', 'Monthly', Icons.calendar_month_rounded),
      ('yearly', 'Yearly', Icons.event_repeat_rounded),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── هێڵی سەرەوە ──────────────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isEditing ? "Edit Reminder" : "New Reminder",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── ناونیشان ─────────────────────────────────────
                  TextField(
                    controller: titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style:
                        const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: "Reminder title *",
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── نۆتی تایبەت ──────────────────────────────────
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF2C2C2C)),
                    decoration: InputDecoration(
                      hintText: "Add a note (optional)",
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── هەڵبژاردنی کات ───────────────────────────────
                  const Text("Date & Time",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A8A8A))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // ڕێکەوت
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365 * 5)),
                            );
                            if (d != null) {
                              setSheet(() => selectedDate = DateTime(
                                  d.year,
                                  d.month,
                                  d.day,
                                  selectedTime.hour,
                                  selectedTime.minute));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 16, color: Color(0xFF5C5C5C)),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(selectedDate),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // کات
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (t != null) {
                              setSheet(() {
                                selectedTime = t;
                                selectedDate = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    t.hour,
                                    t.minute);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 16, color: Color(0xFF5C5C5C)),
                                const SizedBox(width: 8),
                                Text(
                                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── دووبارەبوونەوە ────────────────────────────────
                  const Text("Repeat",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A8A8A))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: repeatOptions.map((opt) {
                      final isSelected = repeatType == opt.$1;
                      return GestureDetector(
                        onTap: () => setSheet(() => repeatType = opt.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(opt.$3,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF5C5C5C)),
                              const SizedBox(width: 6),
                              Text(
                                opt.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2C2C2C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // ── هەڵبژاردنی ڕۆژانی هەفتە (تەنها بۆ Weekly) ───
                  if (repeatType == 'weekly') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      children: weekdays.map((day) {
                        final isSel = selectedWeekdays.contains(day);
                        return GestureDetector(
                          onTap: () => setSheet(() {
                            if (isSel) {
                              selectedWeekdays.remove(day);
                            } else {
                              selectedWeekdays.add(day);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? Colors.orange.shade600
                                  : const Color(0xFFF5F5F5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                day.substring(0, 2),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? Colors.white
                                      : const Color(0xFF5C5C5C),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── دوگمەکان ─────────────────────────────────────
                  Row(
                    children: [
                      if (isEditing)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteReminder(index);
                          },
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          label: const Text("Delete",
                              style: TextStyle(color: Colors.red)),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.black45)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          await _saveReminder(
                            index: index,
                            title: titleCtrl.text.trim(),
                            note: noteCtrl.text.trim(),
                            dateTime: selectedDate,
                            repeatType: repeatType,
                            weekdays: selectedWeekdays,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: Text(isEditing ? "Update" : "Set Reminder"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── هەڵگرتنی ریمایندەر ──────────────────────────────────────────────────
  Future<void> _saveReminder({
    required int? index,
    required String title,
    required String note,
    required DateTime dateTime,
    required String repeatType,
    required List<String> weekdays,
  }) async {
    if (widget.onRequestAlarm != null) {
      final granted = await widget.onRequestAlarm!();
      if (!granted) return;
    }

    if (dateTime.isBefore(DateTime.now()) && repeatType == 'none') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please select a future date & time"),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final id = index != null
        ? (_reminders[index]['id'] as int)
        : DateTime.now().millisecondsSinceEpoch;

    await NotificationService.cancelReminder(id);

    final reminder = {
      'id': id,
      'title': title,
      'note': note,
      'dateTime': dateTime.toIso8601String(),
      'repeatType': repeatType,
      'weekdays': weekdays,
      'isDone': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (index == null) {
      _reminders.add(reminder);
    } else {
      _reminders[index] = reminder;
    }

    await _saveReminders();

    await NotificationService.scheduleReminder(
      dateTime,
      title,
      note.isEmpty ? '🔔 Tap to view' : note,
      id,
    );

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Reminder set for ${_formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}"),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── سڕینەوەی ریمایندەر ──────────────────────────────────────────────────
  void _deleteReminder(int index) {
    final r = _reminders[index];
    NotificationService.cancelReminder(r['id'] as int);
    setState(() => _reminders.removeAt(index));
    _saveReminders();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Reminder deleted"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() => _reminders.insert(index, r));
            _saveReminders();
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── نیشانکردن وەک تەواوبوو ──────────────────────────────────────────────
  Future<void> _markDone(int index) async {
    final r = _reminders[index];
    NotificationService.cancelReminder(r['id'] as int);
    setState(() => _reminders[index]['isDone'] = true);
    await _saveReminders();
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _repeatLabel(Map<String, dynamic> r) {
    switch (r['repeatType']) {
      case 'daily':
        return '🔁 Daily';
      case 'weekly':
        final days = (r['weekdays'] as List?)?.join(', ') ?? '';
        return days.isNotEmpty ? '🔁 Weekly · $days' : '🔁 Weekly';
      case 'monthly':
        return '🔁 Monthly';
      case 'yearly':
        return '🔁 Yearly';
      default:
        return '';
    }
  }

  bool _isOverdue(DateTime dt) => dt.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final reminders = _filteredReminders;
    final allCount = _reminders.where((r) => r['isDone'] != true).length;
    final todayCount = _reminders.where((r) {
      final dt = DateTime.parse(r['dateTime']);
      final now = DateTime.now();
      return dt.day == now.day &&
          dt.month == now.month &&
          dt.year == now.year &&
          r['isDone'] != true;
    }).length;
    final upcomingCount = _reminders
        .where((r) =>
            DateTime.parse(r['dateTime']).isAfter(DateTime.now()) &&
            r['isDone'] != true)
        .length;
    final doneCount = _reminders.where((r) => r['isDone'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Reminders",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_reminders.any((r) => r['isDone'] == true))
            TextButton(
              onPressed: () {
                setState(
                    () => _reminders.removeWhere((r) => r['isDone'] == true));
                _saveReminders();
              },
              child: const Text("Clear done",
                  style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _filterChip('all', 'All', allCount),
                const SizedBox(width: 8),
                _filterChip('today', 'Today', todayCount),
                const SizedBox(width: 8),
                _filterChip('upcoming', 'Upcoming', upcomingCount),
                const SizedBox(width: 8),
                _filterChip('done', 'Done', doneCount),
              ],
            ),
          ),
        ),
      ),
      body: reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_outlined,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _filter == 'done'
                        ? "No completed reminders"
                        : "No reminders",
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  if (_filter == 'all') ...[
                    const SizedBox(height: 8),
                    Text("Tap + to set a reminder",
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ]
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reminders.length,
              itemBuilder: (context, i) {
                final r = reminders[i];
                final realIndex = _reminders.indexOf(r);
                final dt = DateTime.parse(r['dateTime']);
                final isDone = r['isDone'] == true;
                final isOverdue = !isDone && _isOverdue(dt);
                final repeatLabel = _repeatLabel(r);

                return Dismissible(
                  key: Key(r['id'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: Colors.white, size: 24),
                  ),
                  onDismissed: (_) => _deleteReminder(realIndex),
                  child: GestureDetector(
                    onTap: () => _openReminderDialog(index: realIndex),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isOverdue
                            ? Border.all(color: Colors.red.shade200, width: 1)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── چێکبۆکس ──────────────────────────────
                          GestureDetector(
                            onTap: isDone ? null : () => _markDone(realIndex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? Colors.green.shade400
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isDone
                                      ? Colors.green.shade400
                                      : isOverdue
                                          ? Colors.red.shade300
                                          : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: isDone
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // ── ناوەرۆک ──────────────────────────────
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['title'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDone
                                        ? Colors.grey.shade400
                                        : const Color(0xFF1A1A1A),
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if ((r['note'] as String?)?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    r['note'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    // کاتی زەنگ
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOverdue
                                            ? Colors.red.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.alarm_rounded,
                                            size: 12,
                                            color: isOverdue
                                                ? Colors.red.shade400
                                                : Colors.orange.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_formatDate(dt)} · ${_formatTime(dt)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isOverdue
                                                  ? Colors.red.shade400
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ریپیت
                                    if (repeatLabel.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          repeatLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ),
                                    // تەواوبوو
                                    if (isDone)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "✓ Done",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReminderDialog(),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text("Add Reminder",
            style: TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _filterChip(String value, String label, int count) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade200,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF5C5C5C),
          ),
        ),
      ),
    );
  }
}
