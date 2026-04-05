import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_dialog.dart';

class TasksScreen extends StatefulWidget {
  final Color bgColor;
  final Color textColor;
  final Future<bool> Function()? onRequestAlarm;
  final VoidCallback onTaskChanged;

  const TasksScreen({
    super.key,
    required this.bgColor,
    required this.textColor,
    this.onRequestAlarm,
    required this.onTaskChanged,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  String _selectedFilter = 'all'; // all, today, week, month, year

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final all = await _taskService.getAllTasks();
    if (mounted) setState(() => _tasks = all.where((t) => t.isVisible).toList());
  }

  List<Task> get _filteredTasks {
    if (_selectedFilter == 'all') return _tasks;
    return _tasks.where((t) => t.autoCategory == _selectedFilter).toList();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'today': return 'Today';
      case 'week': return 'This Week';
      case 'month': return 'This Month';
      case 'year': return 'This Year';
      default: return 'Task';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'today': return Colors.orange;
      case 'week': return Colors.green;
      case 'month': return Colors.blue;
      case 'year': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.bgColor.computeLuminance() < 0.5;
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF8A8A8A);
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.7);
    final filteredTasks = _filteredTasks;

    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        title: const Text("My Tasks"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filterChip('all', 'All', filteredTasks.length),
                _filterChip('today', 'Today', _tasks.where((t) => t.autoCategory == 'today').length),
                _filterChip('week', 'Week', _tasks.where((t) => t.autoCategory == 'week').length),
                _filterChip('month', 'Month', _tasks.where((t) => t.autoCategory == 'month').length),
                _filterChip('year', 'Year', _tasks.where((t) => t.autoCategory == 'year').length),
              ],
            ),
          ),
        ),
      ),
      body: filteredTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt_outlined, size: 64, color: subTextColor),
                  const SizedBox(height: 16),
                  Text("No tasks yet", style: TextStyle(color: subTextColor)),
                  const SizedBox(height: 8),
                  Text("Tap + to add a task", style: TextStyle(color: subTextColor, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(color: _getCategoryColor(task.autoCategory), width: 4),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: GestureDetector(
                      onTap: () async {
                        await _taskService.markDone(task.id);
                        _loadTasks();
                        widget.onTaskChanged();
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.textColor.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: task.isDone ? Icon(Icons.check, size: 16, color: widget.textColor) : null,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 15,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.content.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              task.content,
                              style: TextStyle(fontSize: 12, color: subTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(task.autoCategory).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getCategoryLabel(task.autoCategory),
                                style: TextStyle(fontSize: 10, color: _getCategoryColor(task.autoCategory)),
                              ),
                            ),
                            if (task.scheduledTime != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.access_time, size: 12, color: subTextColor),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(task.scheduledTime),
                                style: TextStyle(fontSize: 11, color: subTextColor),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 18, color: subTextColor),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (_) => TaskDialog(
                                bgColor: widget.bgColor,
                                textColor: widget.textColor,
                                onTaskAdded: () {
                                  _loadTasks();
                                  widget.onTaskChanged();
                                },
                                onRequestAlarm: widget.onRequestAlarm,
                                editTask: task,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: subTextColor),
                          onPressed: () async {
                            await _taskService.hideTask(task.id);
                            _loadTasks();
                            widget.onTaskChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => TaskDialog(
              bgColor: widget.bgColor,
              textColor: widget.textColor,
              onTaskAdded: () {
                _loadTasks();
                widget.onTaskChanged();
              },
              onRequestAlarm: widget.onRequestAlarm,
            ),
          );
        },
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _filterChip(String value, String label, int count) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FilterChip(
          label: Text('$label ($count)'),
          selected: _selectedFilter == value,
          onSelected: (selected) {
            setState(() => _selectedFilter = value);
          },
          backgroundColor: Colors.transparent,
          selectedColor: Colors.blueGrey.withValues(alpha: 0.5),
          labelStyle: TextStyle(
            color: _selectedFilter == value ? Colors.white : widget.textColor,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}