import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskPanel extends StatefulWidget {
  final String category;
  final List<Task> tasks;
  final Color bgColor;
  final Color textColor;
  final Color cardColor;
  final Color subTextColor;
  final VoidCallback onTasksChanged;
  final Future<bool> Function()? onRequestAlarm;

  const TaskPanel({
    super.key,
    required this.category,
    required this.tasks,
    required this.bgColor,
    required this.textColor,
    required this.cardColor,
    required this.subTextColor,
    required this.onTasksChanged,
    this.onRequestAlarm,
  });

  @override
  State<TaskPanel> createState() => _TaskPanelState();
}

class _TaskPanelState extends State<TaskPanel>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) return;

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

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: widget.category,
      scheduledTime: scheduledTime,
    );

    await _taskService.addTask(task);
    _titleController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
    });
    widget.onTasksChanged();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && mounted) setState(() => _selectedTime = time);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _categoryLabel() {
    switch (widget.category) {
      case 'today':
        return "Today's Tasks";
      case 'week':
        return "This Week";
      case 'month':
        return "This Month";
      case 'year':
        return "This Year";
      default:
        return "Tasks";
    }
  }

  // نیشاندانی کاتی دیاریکراو لەسەر تایم لاین
  bool _isWithin24Hours(Task task) {
    if (task.scheduledTime == null) return false;
    final diff = task.scheduledTime!.difference(DateTime.now());
    return diff.inHours >= 0 && diff.inHours <= 24;
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = widget.tasks.where((t) => t.isVisible).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.textColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // هێدەری کشۆ
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.task_alt_outlined,
                      color: widget.textColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _categoryLabel(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.textColor,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (visibleTasks.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.textColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${visibleTasks.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: widget.subTextColor),
                  ),
                ],
              ),
            ),
          ),

          // ناوەڕۆکی کشۆ
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                Divider(
                    height: 1,
                    color: widget.textColor.withValues(alpha: 0.08)),

                // فۆرمی زیادکردن
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              style: TextStyle(color: widget.textColor),
                              decoration: InputDecoration(
                                hintText: "Add task...",
                                hintStyle: TextStyle(
                                    color: widget.subTextColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: widget.textColor
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: widget.textColor
                                        .withValues(alpha: 0.15),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addTask,
                            icon: Icon(Icons.add_circle,
                                color: widget.textColor, size: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // کات و بەروار
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: Icon(Icons.calendar_today,
                                  size: 14, color: widget.subTextColor),
                              label: Text(
                                _selectedDate != null
                                    ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                                    : "Date",
                                style: TextStyle(
                                    fontSize: 12, color: widget.subTextColor),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                side: BorderSide(
                                    color: widget.textColor
                                        .withValues(alpha: 0.15)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: Icon(Icons.access_time,
                                  size: 14, color: widget.subTextColor),
                              label: Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : "Time",
                                style: TextStyle(
                                    fontSize: 12, color: widget.subTextColor),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                side: BorderSide(
                                    color: widget.textColor
                                        .withValues(alpha: 0.15)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // لیستی کاروبارەکان
                if (visibleTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "No tasks yet",
                      style: TextStyle(color: widget.subTextColor),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleTasks.length,
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      return _buildTaskItem(task);
                    },
                  ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final isWithin24h = _isWithin24Hours(task);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: widget.bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isWithin24h ? Colors.orange : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: GestureDetector(
          onTap: () async {
            await _taskService.markDone(task.id);
            widget.onTasksChanged();
          },
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: widget.textColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: task.isDone
                ? Icon(Icons.check, size: 14, color: widget.textColor)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: widget.textColor,
            fontSize: 14,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.scheduledTime != null
            ? Text(
                _formatTime(task.scheduledTime),
                style: TextStyle(
                  fontSize: 11,
                  color: isWithin24h ? Colors.orange : widget.subTextColor,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // بینیم
            GestureDetector(
              onTap: () async {
                await _taskService.hideTask(task.id);
                widget.onTasksChanged();
              },
              child: Icon(Icons.visibility_off_outlined,
                  size: 16, color: widget.subTextColor),
            ),
            const SizedBox(width: 8),
            // سرینەوە
            GestureDetector(
              onTap: () async {
                await _taskService.deleteTask(task.id);
                widget.onTasksChanged();
              },
              child: Icon(Icons.close,
                  size: 16, color: widget.subTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
