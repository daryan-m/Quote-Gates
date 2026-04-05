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
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
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
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersString = prefs.getString('user_reminders');
    if (remindersString != null) {
      setState(() {
        _reminders =
            List<Map<String, dynamic>>.from(json.decode(remindersString));
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_reminders', json.encode(_reminders));
  }

  Future<void> _addReminder() async {
    if (_titleController.text.trim().isEmpty) return;

    if (widget.onRequestAlarm != null) {
      final granted = await widget.onRequestAlarm!();
      if (!granted) return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now()) &&
        !_isRecurringWeekly &&
        !_isRecurringDaily &&
        !_isRecurringMonthly &&
        !_isRecurringYearly) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a future time")),
      );
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch;

    String repeatType = 'none';
    if (_isRecurringDaily) {
      repeatType = 'daily';
    } else if (_isRecurringWeekly) {
      repeatType = 'weekly';
    } else if (_isRecurringMonthly) {
      repeatType = 'monthly';
    } else if (_isRecurringYearly) {
      repeatType = 'yearly';
    }

    final reminder = {
      'id': id,
      'title': _titleController.text,
      'dateTime': scheduledDateTime.toIso8601String(),
      'repeatType': repeatType,
      'weekdays': _selectedWeekdays,
      'customDays': _customRepeatDays,
    };

    _reminders.add(reminder);
    await _saveReminders();

    await NotificationService.scheduleReminder(
      scheduledDateTime,
      _titleController.text,
      "🔔 ${_titleController.text}",
      id,
    );

    _titleController.clear();
    _selectedWeekdays = [];
    _isRecurringDaily = false;
    _isRecurringWeekly = false;
    _isRecurringMonthly = false;
    _isRecurringYearly = false;
    _customRepeatDays = null;
    setState(() {});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reminder set successfully")),
    );
  }

  Future<void> _deleteReminder(int index, int id) async {
    await NotificationService.cancelReminder(id);
    _reminders.removeAt(index);
    await _saveReminders();
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reminder deleted")),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (!mounted) return;
    if (time != null) setState(() => _selectedTime = time);
  }

  String _getRepeatText(Map<String, dynamic> reminder) {
    final type = reminder['repeatType'];
    if (type == 'daily') return '🔁 Daily';
    if (type == 'weekly') {
      final weekdays = reminder['weekdays'] as List?;
      if (weekdays != null && weekdays.isNotEmpty) {
        return '🔁 Weekly on ${weekdays.join(', ')}';
      }
      return '🔁 Weekly';
    }
    if (type == 'monthly') return '🔁 Monthly';
    if (type == 'yearly') return '🔁 Yearly';
    if (reminder['customDays'] != null) {
      return '🔁 Every ${reminder['customDays']} days';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                          hintText: "Reminder title",
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                                "${_selectedDate.toLocal()}".split(' ')[0]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_selectedTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                      decoration: const InputDecoration(
                          hintText: "Custom repeat (days)"),
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          setState(() => _customRepeatDays = int.tryParse(val)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: _addReminder,
                        child: const Text("Set Reminder")),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _reminders.isEmpty
                ? const Center(child: Text("No reminders yet"))
                : ListView.builder(
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      final dateTime = DateTime.parse(reminder['dateTime']);
                      final repeatText = _getRepeatText(reminder);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading:
                              const Icon(Icons.alarm, color: Colors.orange),
                          title: Text(reminder['title']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${dateTime.toLocal()}"
                                  .replaceAll('.000', '')),
                              if (repeatText.isNotEmpty)
                                Text(repeatText,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.blueGrey)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteReminder(index, reminder['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
