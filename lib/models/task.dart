class Task {
  final String id;
  String title;
  String content; // ناوەڕۆک زیاد کرا
  DateTime? scheduledTime;
  bool isDone;
  bool isVisible;
  int reminderCount;
  DateTime? createdAt;
  
  // بۆ دووبارەبوونەوە
  String? repeatType; // daily, weekly, monthly, yearly
  List<String>? weekdays;
  int? customRepeatDays;

  Task({
    required this.id,
    required this.title,
    this.content = '',
    this.scheduledTime,
    this.isDone = false,
    this.isVisible = true,
    this.reminderCount = 0,
    DateTime? createdAt,
    this.repeatType,
    this.weekdays,
    this.customRepeatDays,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : null,
      isDone: json['isDone'] ?? false,
      isVisible: json['isVisible'] ?? true,
      reminderCount: json['reminderCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      repeatType: json['repeatType'],
      weekdays: json['weekdays'] != null ? List<String>.from(json['weekdays']) : null,
      customRepeatDays: json['customRepeatDays'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'scheduledTime': scheduledTime?.toIso8601String(),
        'isDone': isDone,
        'isVisible': isVisible,
        'reminderCount': reminderCount,
        'createdAt': createdAt?.toIso8601String(),
        'repeatType': repeatType,
        'weekdays': weekdays,
        'customRepeatDays': customRepeatDays,
      };

  Task copyWith({
    String? title,
    String? content,
    DateTime? scheduledTime,
    bool? isDone,
    bool? isVisible,
    int? reminderCount,
    String? repeatType,
    List<String>? weekdays,
    int? customRepeatDays,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isDone: isDone ?? this.isDone,
      isVisible: isVisible ?? this.isVisible,
      reminderCount: reminderCount ?? this.reminderCount,
      createdAt: createdAt,
      repeatType: repeatType ?? this.repeatType,
      weekdays: weekdays ?? this.weekdays,
      customRepeatDays: customRepeatDays ?? this.customRepeatDays,
    );
  }

  // بۆ پۆلێنکردنی ئۆتۆماتیکی بەپێی کات
  String get autoCategory {
    if (scheduledTime == null) return 'today';
    final now = DateTime.now();
    final diff = scheduledTime!.difference(now);
    
    if (diff.inDays < 1) return 'today';
    if (diff.inDays < 7) return 'week';
    if (diff.inDays < 30) return 'month';
    return 'year';
  }
}