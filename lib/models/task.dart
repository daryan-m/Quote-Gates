class Task {
  final String id;
  final String title;
  final String content;
  final DateTime? scheduledTime;
  final bool isDone;
  final bool isVisible;
  final int reminderCount;
  final String? repeatType;
  final List<String>? weekdays;
  final int? customRepeatDays;
  final String? priority; // 'none', 'low', 'medium', 'high'

  const Task({
    required this.id,
    required this.title,
    this.content = '',
    this.scheduledTime,
    this.isDone = false,
    this.isVisible = true,
    this.reminderCount = 0,
    this.repeatType,
    this.weekdays,
    this.customRepeatDays,
    this.priority = 'none',
  });

  // ── کەتگۆری ئۆتۆماتیکی ──────────────────────────────────────────────────
  String get autoCategory {
    if (scheduledTime == null) return 'none';
    final diff = scheduledTime!.difference(DateTime.now());
    if (diff.inDays < 1) return 'today';
    if (diff.inDays < 7) return 'week';
    if (diff.inDays < 30) return 'month';
    return 'year';
  }

  // ── کۆپیکردن بە گۆڕانکاری ───────────────────────────────────────────────
  Task copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? scheduledTime,
    bool? isDone,
    bool? isVisible,
    int? reminderCount,
    String? repeatType,
    List<String>? weekdays,
    int? customRepeatDays,
    String? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isDone: isDone ?? this.isDone,
      isVisible: isVisible ?? this.isVisible,
      reminderCount: reminderCount ?? this.reminderCount,
      repeatType: repeatType ?? this.repeatType,
      weekdays: weekdays ?? this.weekdays,
      customRepeatDays: customRepeatDays ?? this.customRepeatDays,
      priority: priority ?? this.priority,
    );
  }

  // ── JSON ─────────────────────────────────────────────────────────────────
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : null,
      isDone: json['isDone'] as bool? ?? false,
      isVisible: json['isVisible'] as bool? ?? true,
      reminderCount: json['reminderCount'] as int? ?? 0,
      repeatType: json['repeatType'] as String?,
      weekdays: json['weekdays'] != null
          ? List<String>.from(json['weekdays'] as List)
          : null,
      customRepeatDays: json['customRepeatDays'] as int?,
      priority: json['priority'] as String? ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'isDone': isDone,
      'isVisible': isVisible,
      'reminderCount': reminderCount,
      'repeatType': repeatType,
      'weekdays': weekdays,
      'customRepeatDays': customRepeatDays,
      'priority': priority,
    };
  }
}