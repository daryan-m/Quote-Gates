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

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  String _selectedFilter = 'all';
  late TabController _tabController;

  final List<String> _filters = ['all', 'today', 'week', 'month', 'year'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedFilter = _filters[_tabController.index]);
      }
    });
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final all = await _taskService.getAllTasks();
    if (mounted) {
      setState(() => _tasks = all.where((t) => t.isVisible).toList());
    }
  }

  List<Task> get _filteredTasks {
    List<Task> list = _selectedFilter == 'all'
        ? _tasks
        : _tasks.where((t) => t.autoCategory == _selectedFilter).toList();

    list.sort((a, b) {
      final pa = _priorityValue(a.priority);
      final pb = _priorityValue(b.priority);
      if (pa != pb) return pb.compareTo(pa);
      if (a.scheduledTime != null && b.scheduledTime != null) {
        return a.scheduledTime!.compareTo(b.scheduledTime!);
      }
      return 0;
    });

    return list;
  }

  int _priorityValue(String? p) {
    switch (p) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  Color _priorityColor(String? p) {
    switch (p) {
      case 'high':
        return Colors.red.shade400;
      case 'medium':
        return Colors.orange.shade400;
      case 'low':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'today':
        return Colors.orange;
      case 'week':
        return Colors.green;
      case 'month':
        return Colors.blue;
      case 'year':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      default:
        return 'No date';
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  int _countFor(String filter) => filter == 'all'
      ? _tasks.length
      : _tasks.where((t) => t.autoCategory == filter).length;

  Future<void> _openAddEdit({Task? task}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskAddScreen(
          bgColor: widget.bgColor,
          textColor: widget.textColor,
          onRequestAlarm: widget.onRequestAlarm,
          editTask: task,
          onSaved: () {
            _loadTasks();
            widget.onTaskChanged();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.bgColor.computeLuminance() < 0.5;
    final subColor = isDark ? Colors.white60 : const Color(0xFF8A8A8A);
    final cardColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;

    final filtered = _filteredTasks;

    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        title: const Text("Tasks",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: widget.bgColor,
        foregroundColor: widget.textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: widget.textColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: widget.textColor,
          unselectedLabelColor: subColor,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _filters
              .map((f) => Tab(
                    text: f == 'all'
                        ? 'All (${_countFor(f)})'
                        : '${f[0].toUpperCase()}${f.substring(1)} (${_countFor(f)})',
                  ))
              .toList(),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt_outlined,
                      size: 72, color: subColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text("No tasks",
                      style: TextStyle(
                          color: subColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text("Tap + to add a task",
                      style: TextStyle(color: subColor, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final task = filtered[i];

                return Dismissible(
                  key: Key(task.id),
                  background: _swipeBackground(Colors.green.shade400,
                      Icons.check_rounded, Alignment.centerLeft),
                  secondaryBackground: _swipeBackground(Colors.red.shade400,
                      Icons.delete_rounded, Alignment.centerRight),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await _taskService.markDone(task.id);
                      _loadTasks();
                      widget.onTaskChanged();
                      return false;
                    } else {
                      return true;
                    }
                  },
                  onDismissed: (_) async {
                    await _taskService.deleteTask(task.id);
                    _loadTasks();
                    widget.onTaskChanged();
                  },
                  child: GestureDetector(
                    onTap: () => _openAddEdit(task: task),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border(
                          left: BorderSide(
                            color: _categoryColor(task.autoCategory),
                            width: 4,
                          ),
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await _taskService.markDone(task.id);
                                _loadTasks();
                                widget.onTaskChanged();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: task.isDone
                                      ? Colors.green.shade400
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: task.isDone
                                        ? Colors.green.shade400
                                        : widget.textColor
                                            .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: task.isDone
                                    ? const Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (task.priority != null &&
                                          task.priority != 'none')
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(
                                              right: 6, top: 4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                _priorityColor(task.priority),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: task.isDone
                                                ? subColor
                                                : widget.textColor,
                                            decoration: task.isDone
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (task.content.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      task.content,
                                      style: TextStyle(
                                          fontSize: 12, color: subColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _chip(
                                        _categoryLabel(task.autoCategory),
                                        _categoryColor(task.autoCategory)
                                            .withValues(alpha: 0.15),
                                        _categoryColor(task.autoCategory),
                                      ),
                                      if (task.scheduledTime != null)
                                        _chip(
                                          '⏰ ${_formatTime(task.scheduledTime)}',
                                          subColor.withValues(alpha: 0.1),
                                          subColor,
                                        ),
                                      if (task.priority != null &&
                                          task.priority != 'none')
                                        _chip(
                                          '${task.priority![0].toUpperCase()}${task.priority!.substring(1)}',
                                          _priorityColor(task.priority)
                                              .withValues(alpha: 0.15),
                                          _priorityColor(task.priority),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        backgroundColor: widget.textColor,
        foregroundColor: widget.bgColor,
        icon: const Icon(Icons.add),
        label: const Text("Add Task",
            style: TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _swipeBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
