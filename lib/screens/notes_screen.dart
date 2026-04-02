// شاشەی یادداشتەکان - نووسین و هەڵگرتنی یادداشت لە مۆبایلدا
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  int? _editingIndex;

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
    if (index != null) {
      _editingIndex = index;
      _titleController.text = _notes[index]['title'];
      _contentController.text = _notes[index]['content'];
    } else {
      _editingIndex = null;
      _titleController.clear();
      _contentController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_editingIndex == null ? "New Note" : "Edit Note"),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty &&
                  _contentController.text.isNotEmpty) {
                if (_editingIndex == null) {
                  _notes.add({
                    'title': _titleController.text,
                    'content': _contentController.text,
                    'date': DateTime.now().toIso8601String(),
                  });
                } else {
                  _notes[_editingIndex!] = {
                    'title': _titleController.text,
                    'content': _contentController.text,
                    'date': DateTime.now().toIso8601String(),
                  };
                }
                _saveNotes();
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteNote(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Note"),
        content: const Text("Are you sure you want to delete this note?"),
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
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
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
