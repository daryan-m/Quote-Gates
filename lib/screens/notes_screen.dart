import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesScreen extends StatefulWidget {
  final Future<bool> Function()? onRequestNotification;
  final Future<bool> Function()? onRequestAlarm;

  const NotesScreen({
    super.key,
    this.onRequestNotification,
    this.onRequestAlarm,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  int? _editingIndex;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _selectedWeekdays = [];
  bool _isRecurringDaily = false;
  bool _isRecurringWeekly = false;
  bool _isRecurringMonthly = false;
  bool _isRecurringYearly = false;
  int? _customRepeatDays;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesString = prefs.getString('user_notes');
    if (notesString != null) {
      setState(() {
        _notes = List<Map<String, dynamic>>.from(json.decode(notesString));
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_notes', json.encode(_notes));
  }

  void _openNoteDialog({int? index}) {
    _selectedDate = null;
    _selectedTime = null;
    _selectedWeekdays = [];
    _isRecurringDaily = false;
    _isRecurringWeekly = false;
    _isRecurringMonthly = false;
    _isRecurringYearly = false;
    _customRepeatDays = null;

    if (index != null) {
      _editingIndex = index;
      _titleController.text = _notes[index]['title'];
      _contentController.text = _notes[index]['content'];

      if (_notes[index].containsKey('reminderDate') &&
          _notes[index]['reminderDate'] != null) {
        _selectedDate = DateTime.parse(_notes[index]['reminderDate']);
      }
      if (_notes[index].containsKey('reminderTime') &&
          _notes[index]['reminderTime'] != null) {
        final parts = _notes[index]['reminderTime'].split(':');
        _selectedTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (_notes[index].containsKey('repeatType') &&
          _notes[index]['repeatType'] != null) {
        final String repeatType = _notes[index]['repeatType'];
        if (repeatType == 'daily') {
          _isRecurringDaily = true;
        } else if (repeatType == 'weekly') {
          _isRecurringWeekly = true;
        } else if (repeatType == 'monthly') {
          _isRecurringMonthly = true;
        } else if (repeatType == 'yearly') {
          _isRecurringYearly = true;
        }
      }
      if (_notes[index].containsKey('weekdays') &&
          _notes[index]['weekdays'] != null) {
        _selectedWeekdays = List<String>.from(_notes[index]['weekdays']);
      }
      if (_notes[index].containsKey('customDays') &&
          _notes[index]['customDays'] != null) {
        _customRepeatDays = _notes[index]['customDays'];
      }
    } else {
      _editingIndex = null;
      _titleController.clear();
      _contentController.clear();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(_editingIndex == null ? "New Note" : "Edit Note"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: "Title"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(hintText: "Content"),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text("Set Reminder (Optional)",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 3650)),
                            );
                            if (date != null) {
                              setDialogState(() => _selectedDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_selectedDate != null
                              ? "${_selectedDate!.toLocal()}".split(' ')[0]
                              : "Select Date"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setDialogState(() => _selectedTime = time);
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(_selectedTime != null
                              ? _selectedTime!.format(context)
                              : "Select Time"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text("Repeat Daily"),
                    value: _isRecurringDaily,
                    onChanged: (val) {
                      setDialogState(() {
                        _isRecurringDaily = val ?? false;
                        if (val == true) {
                          _isRecurringWeekly = false;
                          _isRecurringMonthly = false;
                          _isRecurringYearly = false;
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Repeat Weekly"),
                    value: _isRecurringWeekly,
                    onChanged: (val) {
                      setDialogState(() {
                        _isRecurringWeekly = val ?? false;
                        if (val == true) {
                          _isRecurringDaily = false;
                          _isRecurringMonthly = false;
                          _isRecurringYearly = false;
                        }
                      });
                    },
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
                              setDialogState(() {
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
                    onChanged: (val) {
                      setDialogState(() {
                        _isRecurringMonthly = val ?? false;
                        if (val == true) {
                          _isRecurringDaily = false;
                          _isRecurringWeekly = false;
                          _isRecurringYearly = false;
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Repeat Yearly"),
                    value: _isRecurringYearly,
                    onChanged: (val) {
                      setDialogState(() {
                        _isRecurringYearly = val ?? false;
                        if (val == true) {
                          _isRecurringDaily = false;
                          _isRecurringWeekly = false;
                          _isRecurringMonthly = false;
                        }
                      });
                    },
                  ),
                  TextField(
                    decoration:
                        const InputDecoration(hintText: "Custom repeat (days)"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setDialogState(
                          () => _customRepeatDays = int.tryParse(val));
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  final nav = Navigator.of(context); // ✅ پێش هەر await

                  if (_selectedDate != null && _selectedTime != null) {
                    if (widget.onRequestNotification != null) {
                      final granted = await widget.onRequestNotification!();
                      if (!granted) return;
                    }
                    if (widget.onRequestAlarm != null) {
                      final granted = await widget.onRequestAlarm!();
                      if (!granted) return;
                    }
                  }

                  final newNote = {
                    'title': _titleController.text,
                    'content': _contentController.text,
                    'date': DateTime.now().toIso8601String(),
                    'reminderDate': _selectedDate?.toIso8601String(),
                    'reminderTime': _selectedTime != null
                        ? "${_selectedTime!.hour}:${_selectedTime!.minute}"
                        : null,
                    'repeatType': _isRecurringDaily
                        ? 'daily'
                        : _isRecurringWeekly
                            ? 'weekly'
                            : _isRecurringMonthly
                                ? 'monthly'
                                : _isRecurringYearly
                                    ? 'yearly'
                                    : null,
                    'weekdays': _selectedWeekdays,
                    'customDays': _customRepeatDays,
                  };

                  if (_editingIndex == null) {
                    _notes.add(newNote);
                  } else {
                    _notes[_editingIndex!] = newNote;
                  }

                  await _saveNotes();

                  if (!mounted) return;
                  setState(() {});
                  nav.pop(); // ✅ context بەکارنەهێنا
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteNote(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Note"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _notes.removeAt(index);
              _saveNotes();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No notes yet. Tap + to add one."),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                final hasReminder = note['reminderDate'] != null;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: hasReminder
                        ? const Icon(Icons.alarm, color: Colors.orange)
                        : null,
                    title: Text(
                      note['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      note['content'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openNoteDialog(index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNote(index),
                        ),
                      ],
                    ),
                    onTap: () => _openNoteDialog(index: index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteDialog(),
        tooltip: "Add Note",
        child: const Icon(Icons.add),
      ),
    );
  }
}
