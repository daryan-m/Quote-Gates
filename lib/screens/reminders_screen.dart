import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

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
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now()) && !_isRecurringWeekly) {
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
    };

    _reminders.add(reminder);
    await _saveReminders();

    // Schedule notification
    await NotificationService.scheduleReminder(
      scheduledDateTime,
      _titleController.text,
      "Reminder: ${_titleController.text}",
      id,
    );

    _titleController.clear();
    _selectedWeekdays = [];
    _isRecurringDaily = false;
    _isRecurringWeekly = false;
    _isRecurringMonthly = false;
    _isRecurringYearly = false;
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
                                label: Text("${_selectedDate.toLocal()}"
                                    .split(' ')[0]))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: _pickTime,
                                icon: const Icon(Icons.access_time),
                                label: Text(_selectedTime.format(context)))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text("Repeat Daily"),
                      value: _isRecurringDaily,
                      onChanged: (val) => setState(() {
                        _isRecurringDaily = val ?? false;
                        if (val == true) {
                          _isRecurringWeekly =
                              _isRecurringMonthly = _isRecurringYearly = false;
                        }
                      }),
                    ),
                    CheckboxListTile(
                      title: const Text("Repeat Weekly"),
                      value: _isRecurringWeekly,
                      onChanged: (val) => setState(() {
                        _isRecurringWeekly = val ?? false;
                        if (val == true) {
                          _isRecurringDaily =
                              _isRecurringMonthly = _isRecurringYearly = false;
                        }
                      }),
                    ),
                    if (_isRecurringWeekly)
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            'MON',
                            'TUE',
                            'WED',
                            'THU',
                            'FRI',
                            'SAT',
                            'SUN'
                          ].map((day) {
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
                          _isRecurringDaily =
                              _isRecurringWeekly = _isRecurringYearly = false;
                        }
                      }),
                    ),
                    CheckboxListTile(
                      title: const Text("Repeat Yearly"),
                      value: _isRecurringYearly,
                      onChanged: (val) => setState(() {
                        _isRecurringYearly = val ?? false;
                        if (val == true) {
                          _isRecurringDaily =
                              _isRecurringWeekly = _isRecurringMonthly = false;
                        }
                      }),
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
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading:
                              const Icon(Icons.alarm, color: Colors.orange),
                          title: Text(reminder['title']),
                          subtitle: Text(
                              "${dateTime.toLocal()}".replaceAll('.000', '')),
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
