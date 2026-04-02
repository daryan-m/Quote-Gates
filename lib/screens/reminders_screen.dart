// شاشەی بیرخستنەوەکان - دانانی ئاگاداری بۆ کاتی دیاریکراو
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
    final DateTime scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a future time")),
      );
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch;

    await NotificationService.scheduleReminder(
      scheduledDateTime,
      _titleController.text,
      "Reminder: ${_titleController.text}",
      id,
    );

    _reminders.add({
      'id': id,
      'title': _titleController.text,
      'dateTime': scheduledDateTime.toIso8601String(),
    });

    await _saveReminders();
    _titleController.clear();
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
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (!mounted) return;
    if (time != null) {
      setState(() => _selectedTime = time);
    }
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
          // فۆرمی زیادکردنی بیرخستنەوە
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
                        border: OutlineInputBorder(),
                      ),
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
                    ElevatedButton(
                      onPressed: _addReminder,
                      child: const Text("Set Reminder"),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // لیستی بیرخستنەوەکان
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
                            "${dateTime.toLocal()}".replaceAll('.000', ''),
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
