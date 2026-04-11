import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../services/notification_service.dart';

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
  String _searchQuery = '';
  String _sortBy = 'date'; // date, title, reminder

  // ── رەنگەکانی نۆت ───────────────────────────────────────────────────────
  final List<Color> _noteColors = [
    const Color(0xFFFFFDE7),
    const Color(0xFFE8F5E9),
    const Color(0xFFE3F2FD),
    const Color(0xFFFCE4EC),
    const Color(0xFFF3E5F5),
    const Color(0xFFE0F7FA),
    const Color(0xFFFFF3E0),
    const Color(0xFFEFEBE9),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // ── بارکردن و هەڵگرتن ───────────────────────────────────────────────────
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_notes');
    if (raw != null && mounted) {
      setState(
          () => _notes = List<Map<String, dynamic>>.from(json.decode(raw)));
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_notes', json.encode(_notes));
  }

  // ── فیلتەر و ستکردن ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredNotes {
    var list = _notes.where((n) {
      final q = _searchQuery.toLowerCase();
      return n['title'].toString().toLowerCase().contains(q) ||
          n['content'].toString().toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      if (_sortBy == 'title') {
        return a['title'].toString().compareTo(b['title'].toString());
      } else if (_sortBy == 'reminder') {
        final aHas = a['reminderDateTime'] != null ? 0 : 1;
        final bHas = b['reminderDateTime'] != null ? 0 : 1;
        return aHas.compareTo(bHas);
      }
      return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
    });

    return list;
  }

  // ── کردنەوەی دیالۆگی نۆت ────────────────────────────────────────────────
  void _openNoteDialog({int? index}) {
    final isEditing = index != null;
    final note = isEditing ? Map<String, dynamic>.from(_notes[index]) : null;

    final titleCtrl = TextEditingController(text: note?['title'] ?? '');
    final contentCtrl = TextEditingController(text: note?['content'] ?? '');
    DateTime? reminderDT = note?['reminderDateTime'] != null
        ? DateTime.parse(note!['reminderDateTime'])
        : null;
    Color selectedColor =
        note?['color'] != null ? Color(note!['color']) : _noteColors[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── هێڵی سەرەوە ──────────────────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── هەڵبژاردنی رەنگ ──────────────────────────────────
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _noteColors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = _noteColors[i];
                        final isSelected = selectedColor == c;
                        return GestureDetector(
                          onTap: () => setSheet(() => selectedColor = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: isSelected ? 32 : 28,
                            height: isSelected ? 32 : 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black45
                                    : Colors.black12,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── ناونیشان ─────────────────────────────────────────
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    decoration: const InputDecoration(
                      hintText: "Title",
                      hintStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black26),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 12),

                  // ── ناوەرۆک ──────────────────────────────────────────
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.3,
                    ),
                    child: TextField(
                      controller: contentCtrl,
                      maxLines: null,
                      style: const TextStyle(
                          fontSize: 15, height: 1.6, color: Color(0xFF2C2C2C)),
                      decoration: const InputDecoration(
                        hintText: "Write your note here...",
                        hintStyle: TextStyle(color: Colors.black26),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 12),

                  // ── ریمایندەری سادە ───────────────────────────────────
                  GestureDetector(
                    onTap: () async => _pickReminderDateTime(ctx, reminderDT,
                        (dt) => setSheet(() => reminderDT = dt)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            reminderDT != null
                                ? Icons.alarm_on_rounded
                                : Icons.alarm_add_rounded,
                            size: 18,
                            color: reminderDT != null
                                ? Colors.orange.shade700
                                : Colors.black45,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reminderDT != null
                                  ? _formatDateTime(reminderDT!)
                                  : "Add reminder (optional)",
                              style: TextStyle(
                                fontSize: 13,
                                color: reminderDT != null
                                    ? Colors.orange.shade700
                                    : Colors.black45,
                                fontWeight: reminderDT != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (reminderDT != null)
                            GestureDetector(
                              onTap: () => setSheet(() => reminderDT = null),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.black38),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── دوگمەکان ─────────────────────────────────────────
                  Row(
                    children: [
                      if (isEditing)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteNote(index);
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
                          if (titleCtrl.text.trim().isEmpty &&
                              contentCtrl.text.trim().isEmpty) {
                            return;
                          }
                          await _saveNote(
                            index: index,
                            title: titleCtrl.text.trim(),
                            content: contentCtrl.text.trim(),
                            reminderDT: reminderDT,
                            color: selectedColor,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: Text(isEditing ? "Update" : "Save"),
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

  // ── هەڵبژاردنی کات و ڕێکەوتی ریمایندەر ─────────────────────────────────
  Future<void> _pickReminderDateTime(BuildContext ctx, DateTime? current,
      void Function(DateTime?) onPicked) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: current ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !ctx.mounted) return;

    final time = await showTimePicker(
      context: ctx,
      initialTime: current != null
          ? TimeOfDay(hour: current.hour, minute: current.minute)
          : TimeOfDay.fromDateTime(
              DateTime.now().add(const Duration(hours: 1))),
    );
    if (time == null) return;

    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  // ── هەڵگرتنی نۆت ────────────────────────────────────────────────────────
  Future<void> _saveNote({
    required int? index,
    required String title,
    required String content,
    required DateTime? reminderDT,
    required Color color,
  }) async {
    // لەکاتی ویستیان بەکارهێنانی ریمایندەر ڕێپێدان بوێستێت
    if (reminderDT != null && widget.onRequestAlarm != null) {
      final granted = await widget.onRequestAlarm!();
      if (!granted) return;
    }

    final id = index != null
        ? (_notes[index]['id'] as int? ?? DateTime.now().millisecondsSinceEpoch)
        : DateTime.now().millisecondsSinceEpoch;

    // هەڵوەشاندنەوەی ریمایندەری کونەکە
    await NotificationService.cancelReminder(id);

    final note = {
      'id': id,
      'title': title.isEmpty ? 'Untitled' : title,
      'content': content,
      'date': DateTime.now().toIso8601String(),
      'reminderDateTime': reminderDT?.toIso8601String(),
      'color': color.toARGB32(),
    };

    if (index == null) {
      _notes.insert(0, note);
    } else {
      _notes[index] = note;
    }

    await _saveNotes();

    // داڕێژانی ریمایندەری نوێ
    if (reminderDT != null) {
      await NotificationService.scheduleReminder(
        reminderDT,
        note['title'] as String,
        content.isEmpty ? '📝 Tap to open' : content,
        id,
      );
    }

    if (mounted) setState(() {});
  }

  // ── سڕینەوەی نۆت ────────────────────────────────────────────────────────
  void _deleteNote(int index) {
    final note = _notes[index];
    final id = note['id'] as int?;
    if (id != null) NotificationService.cancelReminder(id);

    setState(() => _notes.removeAt(index));
    _saveNotes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Note deleted"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() => _notes.insert(index, note));
            _saveNotes();
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} · $h:$m';
  }

  String _timeAgo(String iso) {
    final dt = DateTime.parse(iso);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDateTime(dt).split('·').first.trim();
  }

  @override
  Widget build(BuildContext context) {
    final notes = _filteredNotes;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Notes",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'date', child: Text("Sort by Date")),
              PopupMenuItem(value: 'title', child: Text("Sort by Title")),
              PopupMenuItem(value: 'reminder', child: Text("Sort by Reminder")),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search notes...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_outlined,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? "No notes yet" : "No results found",
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text("Tap + to create your first note",
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ]
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: notes.length,
              itemBuilder: (context, i) {
                final note = notes[i];
                final realIndex = _notes.indexOf(note);
                final bgColor = note['color'] != null
                    ? Color(note['color'] as int)
                    : _noteColors[0];
                final hasReminder = note['reminderDateTime'] != null;

                return GestureDetector(
                  onTap: () => _openNoteDialog(index: realIndex),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── سەرەوە: ناونیشان + ئایکۆن ──────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                note['title'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasReminder)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(Icons.alarm_rounded,
                                    size: 15, color: Colors.orange.shade600),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // ── ناوەرۆک ─────────────────────────────────
                        Expanded(
                          child: Text(
                            note['content'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4A4A4A),
                              height: 1.5,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // ── خوارەوە: کات ────────────────────────────
                        Row(
                          children: [
                            Text(
                              _timeAgo(note['date']),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black38),
                            ),
                            if (hasReminder) ...[
                              const Spacer(),
                              Text(
                                _formatDateTime(
                                    DateTime.parse(note['reminderDateTime'])),
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.orange.shade600,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteDialog(),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New Note",
            style: TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
