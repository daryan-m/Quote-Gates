class Task {
  final String id;
  String title;
  String category; // today, week, month, year
  DateTime? scheduledTime;
  bool isDone;
  bool isVisible; // بۆ سیستەمی بینیم/ئیتر پیشانم بدەرەوە
  int reminderCount; // چەند جار زەنگی لێدراوە
  DateTime? createdAt;

  Task({
    required this.id,
    required this.title,
    required this.category,
    this.scheduledTime,
    this.isDone = false,
    this.isVisible = true,
    this.reminderCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      category: json['category'] ?? 'today',
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : null,
      isDone: json['isDone'] ?? false,
      isVisible: json['isVisible'] ?? true,
      reminderCount: json['reminderCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'scheduledTime': scheduledTime?.toIso8601String(),
        'isDone': isDone,
        'isVisible': isVisible,
        'reminderCount': reminderCount,
        'createdAt': createdAt?.toIso8601String(),
      };

  Task copyWith({
    String? title,
    String? category,
    DateTime? scheduledTime,
    bool? isDone,
    bool? isVisible,
    int? reminderCount,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isDone: isDone ?? this.isDone,
      isVisible: isVisible ?? this.isVisible,
      reminderCount: reminderCount ?? this.reminderCount,
      createdAt: createdAt,
    );
  }
}
