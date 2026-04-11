import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskAddScreen extends StatefulWidget {
  final Color bgColor;
  final Color textColor;
  final Future<bool> Function()? onRequestAlarm;
  final Task? editTask;
  final VoidCallback onSaved;

  const TaskAddScreen({
    super.key,
    required this.bgColor,
    required this.textColor,
    this.onRequestAlarm,
    this.editTask,
    required this.onSaved,
  });

  @override
  State<TaskAddScreen> createState() => _TaskAddScreenState();
}

class _TaskAddScreenState extends State<TaskAddScreen> {
  final TaskService _taskService = TaskService();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  final FocusNode _titleFocus = FocusNode();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _priority = 'none';
  String _repeatType = 'none';
  List<String> _selectedWeekdays = [];

  final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  final repeatOptions = [
    ('none', 'No repeat'),
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('monthly', 'Monthly'),
    ('yearly', 'Yearly'),
  ];

  final priorityOptions = [
    ('none', 'None', Colors.grey),
    ('low', 'Low', Colors.green),
    ('medium', 'Medium', Colors.orange),
    ('high', 'High', Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editTask != null) {
      final t = widget.editTask!;
      _titleCtrl.text = t.title;
      _contentCtrl.text = t.content;
      _selectedDate = t.scheduledTime;
      if (t.scheduledTime != null) {
        _selectedTime = TimeOfDay(
            hour: t.scheduledTime!.hour, minute: t.scheduledTime!.minute);
      }
      _priority = t.priority ?? 'none';
      _repeatType = t.repeatType ?? 'none';
      _selectedWeekdays = List<String>.from(t.weekdays ?? []);
    }

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _titleFocus.requestFocus());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  bool get _hasDate => _selectedDate != null && _selectedTime != null;

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a task title"),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_hasDate && widget.onRequestAlarm != null) {
      final granted = await widget.onRequestAlarm!();
      if (!granted) return;
    }

    DateTime? scheduledTime;
    if (_selectedDate != null && _selectedTime != null) {
      scheduledTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    if (widget.editTask != null) {
      final updated = widget.editTask!.copyWith(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        scheduledTime: scheduledTime,
        priority: _priority,
        repeatType: _repeatType == 'none' ? null : _repeatType,
        weekdays: _repeatType == 'weekly' ? _selectedWeekdays : null,
      );
      await _taskService.updateTask(updated);
    } else {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        scheduledTime: scheduledTime,
        priority: _priority,
        repeatType: _repeatType == 'none' ? null : _repeatType,
        weekdays: _repeatType == 'weekly' ? _selectedWeekdays : null,
      );
      await _taskService.addTask(task);
    }

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.bgColor.computeLuminance() < 0.5;
    final subColor = isDark ? Colors.white60 : const Color(0xFF8A8A8A);
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F5F5);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF5C5C5C);

    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        backgroundColor: widget.bgColor,
        foregroundColor: widget.textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.editTask != null ? "Edit Task" : "New Task",
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.textColor,
                foregroundColor: widget.bgColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                elevation: 0,
              ),
              child: Text(
                widget.editTask != null ? "Update" : "Save",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ناونیشان ─────────────────────────────────────────────────
            TextField(
              controller: _titleCtrl,
              focusNode: _titleFocus,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: widget.textColor),
              decoration: InputDecoration(
                hintText: "Task title...",
                hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: subColor.withValues(alpha: 0.5)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),

            // ── وەسف ─────────────────────────────────────────────────────
            TextField(
              controller: _contentCtrl,
              maxLines: null,
              style:
                  TextStyle(fontSize: 15, height: 1.6, color: widget.textColor),
              decoration: InputDecoration(
                hintText: "Add description...",
                hintStyle: TextStyle(color: subColor.withValues(alpha: 0.5)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),

            // ── ڕێکەوت و کات ─────────────────────────────────────────────
            _sectionLabel("Date & Time", labelColor),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _pickerButton(
                    icon: Icons.calendar_today_rounded,
                    label: _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : "Select date",
                    color: cardColor,
                    textColor: widget.textColor,
                    subColor: subColor,
                    hasValue: _selectedDate != null,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (d != null) setState(() => _selectedDate = d);
                    },
                    onClear: () => setState(() => _selectedDate = null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _pickerButton(
                    icon: Icons.access_time_rounded,
                    label: _selectedTime != null
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : "Select time",
                    color: cardColor,
                    textColor: widget.textColor,
                    subColor: subColor,
                    hasValue: _selectedTime != null,
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                      );
                      if (t != null) setState(() => _selectedTime = t);
                    },
                    onClear: () => setState(() => _selectedTime = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── پرایۆریتی ─────────────────────────────────────────────────
            _sectionLabel("Priority", labelColor),
            const SizedBox(height: 10),
            Row(
              children: priorityOptions.map((opt) {
                final isSelected = _priority == opt.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = opt.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? opt.$3.withValues(alpha: 0.2)
                            : cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? opt.$3 : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: opt.$3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt.$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? opt.$3 : subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── دووبارەبوونەوە ────────────────────────────────────────────
            _sectionLabel("Repeat", labelColor),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: repeatOptions.map((opt) {
                final isSelected = _repeatType == opt.$1;
                return GestureDetector(
                  onTap: () => setState(() => _repeatType = opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? widget.textColor : cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? widget.bgColor : subColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── ڕۆژانی هەفتە (تەنها بۆ Weekly) ──────────────────────────
            if (_repeatType == 'weekly') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: weekdays.map((day) {
                  final isSel = _selectedWeekdays.contains(day);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSel) {
                        _selectedWeekdays.remove(day);
                      } else {
                        _selectedWeekdays.add(day);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSel ? Colors.orange.shade600 : cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 2),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : subColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _pickerButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required Color subColor,
    required bool hasValue,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hasValue ? textColor : subColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue ? textColor : subColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: subColor),
              ),
          ],
        ),
      ),
    );
  }
}
