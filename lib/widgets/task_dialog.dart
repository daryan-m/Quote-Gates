import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskDialog extends StatefulWidget {
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTaskAdded;
  final Future<bool> Function()? onRequestAlarm;
  final Task? editTask;

  const TaskDialog({
    super.key,
    required this.bgColor,
    required this.textColor,
    required this.onTaskAdded,
    this.onRequestAlarm,
    this.editTask,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final TaskService _taskService = TaskService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // بۆ دووبارەبوونەوە
  List<String> _selectedWeekdays = [];
  bool _isRecurringDaily = false;
  bool _isRecurringWeekly = false;
  bool _isRecurringMonthly = false;
  bool _isRecurringYearly = false;
  int? _customRepeatDays;

  final List<String> _weekdays = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editTask != null) {
      _titleController.text = widget.editTask!.title;
      _contentController.text = widget.editTask!.content;
      _selectedDate = widget.editTask!.scheduledTime;
      if (widget.editTask!.scheduledTime != null) {
        _selectedTime = TimeOfDay(
          hour: widget.editTask!.scheduledTime!.hour,
          minute: widget.editTask!.scheduledTime!.minute,
        );
      }
      _isRecurringDaily = widget.editTask!.repeatType == 'daily';
      _isRecurringWeekly = widget.editTask!.repeatType == 'weekly';
      _isRecurringMonthly = widget.editTask!.repeatType == 'monthly';
      _isRecurringYearly = widget.editTask!.repeatType == 'yearly';
      _selectedWeekdays = widget.editTask!.weekdays ?? [];
      _customRepeatDays = widget.editTask!.customRepeatDays;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) return;

    if (_selectedDate != null && _selectedTime != null) {
      if (widget.onRequestAlarm != null) {
        final granted = await widget.onRequestAlarm!();
        if (!granted) return;
      }
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

    String? repeatType;

    if (_isRecurringDaily) {
      repeatType = 'daily';
    } else if (_isRecurringWeekly) {
      repeatType = 'weekly';
    } else if (_isRecurringMonthly) {
      repeatType = 'monthly';
    } else if (_isRecurringYearly) {
      repeatType = 'yearly';
    }

    if (widget.editTask != null) {
      final updatedTask = widget.editTask!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        scheduledTime: scheduledTime,
        repeatType: repeatType,
        weekdays: _isRecurringWeekly ? _selectedWeekdays : null,
        customRepeatDays: _customRepeatDays,
      );
      await _taskService.updateTask(updatedTask);
    } else {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        scheduledTime: scheduledTime,
        repeatType: repeatType,
        weekdays: _isRecurringWeekly ? _selectedWeekdays : null,
        customRepeatDays: _customRepeatDays,
      );
      await _taskService.addTask(task);
    }

    if (mounted) {
      widget.onTaskAdded();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.bgColor.computeLuminance() < 0.5;
    final dialogBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2C2C2C);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF8A8A8A);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogBgColor,
      child: Container(
        padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.editTask != null ? "Edit Task" : "Add New Task",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Task title...",
                hintStyle: TextStyle(color: subTextColor),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              style: TextStyle(color: textColor),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Description (optional)...",
                hintStyle: TextStyle(color: subTextColor),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null && mounted) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: subTextColor),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDate != null
                                ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                                : "Select Date",
                            style: TextStyle(color: textColor, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime ?? TimeOfDay.now());
                      if (time != null && mounted) {
                        setState(() => _selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 18, color: subTextColor),
                          const SizedBox(width: 8),
                          Text(
                              _selectedTime != null
                                  ? _selectedTime!.format(context)
                                  : "Select Time",
                              style: TextStyle(color: textColor, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text("Repeat (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text("Repeat Daily"),
              value: _isRecurringDaily,
              onChanged: (val) => setState(() {
                _isRecurringDaily = val ?? false;
                if (val == true) {
                  _isRecurringWeekly = false;
                  _isRecurringMonthly = false;
                  _isRecurringYearly = false;
                }
              }),
            ),
            CheckboxListTile(
              title: const Text("Repeat Weekly"),
              value: _isRecurringWeekly,
              onChanged: (val) => setState(() {
                _isRecurringWeekly = val ?? false;
                if (val == true) {
                  _isRecurringDaily = false;
                  _isRecurringMonthly = false;
                  _isRecurringYearly = false;
                }
              }),
            ),
            if (_isRecurringWeekly)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Wrap(
                  spacing: 8,
                  children: _weekdays.map((day) {
                    return FilterChip(
                      label: Text(day),
                      selected: _selectedWeekdays.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWeekdays.add(day);
                          } else {
                            _selectedWeekdays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            CheckboxListTile(
              title: const Text("Repeat Monthly"),
              value: _isRecurringMonthly,
              onChanged: (val) => setState(() {
                _isRecurringMonthly = val ?? false;
                if (val == true) {
                  _isRecurringDaily = false;
                  _isRecurringWeekly = false;
                  _isRecurringYearly = false;
                }
              }),
            ),
            CheckboxListTile(
              title: const Text("Repeat Yearly"),
              value: _isRecurringYearly,
              onChanged: (val) => setState(() {
                _isRecurringYearly = val ?? false;
                if (val == true) {
                  _isRecurringDaily = false;
                  _isRecurringWeekly = false;
                  _isRecurringMonthly = false;
                }
              }),
            ),
            TextField(
              decoration:
                  const InputDecoration(hintText: "Custom repeat (days)"),
              keyboardType: TextInputType.number,
              onChanged: (val) =>
                  setState(() => _customRepeatDays = int.tryParse(val)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                    widget.editTask != null ? "UPDATE TASK" : "SAVE TASK",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
