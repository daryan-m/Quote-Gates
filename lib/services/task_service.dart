import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'notification_service.dart';

class TaskService {
  static const String _tasksKey = 'wisdom_tasks';

  // بارکردنی هەموو کاروبارەکان
  Future<List<Task>> getAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_tasksKey);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((e) => Task.fromJson(e)).toList();
  }

  // بارکردنی کاروبارەکانی کەتگۆری دیاریکراو
  Future<List<Task>> getTasksForCategory(String category) async {
    final all = await getAllTasks();
    return all.where((t) => t.autoCategory == category).toList();
  }

  // ذەخیرەکردنی هەموو کاروبارەکان
  Future<void> _saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _tasksKey, jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  // زیادکردنی کاروبار
  Future<void> addTask(Task task) async {
    final tasks = await getAllTasks();
    tasks.add(task);
    await _saveTasks(tasks);

    // ئەگەر کاتی دیاریکراو هەبوو زەنگ داڕێژە
    if (task.scheduledTime != null) {
      await _scheduleTaskNotification(task);
    }
  }

  // نوێکردنەوەی کاروبار
  Future<void> updateTask(Task task) async {
    final tasks = await getAllTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await _saveTasks(tasks);
    }
  }

  // سڕینەوەی کاروبار
  Future<void> deleteTask(String id) async {
    final tasks = await getAllTasks();
    tasks.removeWhere((t) => t.id == id);
    await _saveTasks(tasks);
    await NotificationService.cancelReminder(id.hashCode);
  }

  // نیشانکردنی کاروبار وەک تەواوبوو
  Future<void> markDone(String id) async {
    final tasks = await getAllTasks();
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(isDone: true);
      await _saveTasks(tasks);
      await NotificationService.cancelReminder(id.hashCode);

      // پاش ١٠ خولەک بسڕەرەوە
      Timer(const Duration(minutes: 10), () async {
        await deleteTask(id);
      });
    }
  }

  // شاردنەوە (پاش بینیم کلیک کرا)
  Future<void> hideTask(String id) async {
    final tasks = await getAllTasks();
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = tasks[index];
      tasks[index] = task.copyWith(
        isVisible: false,
        reminderCount: task.reminderCount + 1,
      );
      await _saveTasks(tasks);

      // پاش ٣ خولەک دووبارە نیشان بدەرەوە و زەنگ بلێژێ
      _scheduleReshow(id, task.reminderCount + 1);
    }
  }

  void _scheduleReshow(String id, int count) {
    // ئەگەر ٥ جاری ٣ خولەک بوو خۆی بسڕدرێتەوە
    if (count >= 5) {
      Timer(const Duration(minutes: 3), () async {
        await deleteTask(id);
      });
      return;
    }

    Timer(const Duration(minutes: 3), () async {
      final tasks = await getAllTasks();
      final index = tasks.indexWhere((t) => t.id == id);
      if (index != -1 && !tasks[index].isDone) {
        tasks[index] = tasks[index].copyWith(isVisible: true);
        await _saveTasks(tasks);

        // زەنگ بلێژێ
        await NotificationService.showTaskReminder(
          tasks[index].title,
          tasks[index].id.hashCode,
        );
      }
    });
  }

  // داڕێژانی زەنگی کاروبار
  Future<void> _scheduleTaskNotification(Task task) async {
    if (task.scheduledTime == null) return;
    await NotificationService.scheduleReminder(
      task.scheduledTime!,
      task.title,
      "⏰ ${task.title}",
      task.id.hashCode,
    );
  }

  // پاکردنەوەی کاروبارە کۆنەکان (دوای ٢٤ کاتژمێر)
  Future<void> cleanOldTasks() async {
    final tasks = await getAllTasks();
    final now = DateTime.now();
    final filtered = tasks.where((t) {
      if (t.scheduledTime == null) return true;
      return now.difference(t.scheduledTime!).inHours < 24;
    }).toList();
    await _saveTasks(filtered);
  }
}
