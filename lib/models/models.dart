import 'package:cloud_firestore/cloud_firestore.dart';

/// Timer / sound / notification settings saved in the user document.
class AppSettings {
  final int focusMin;
  final int shortBreakMin;
  final int longBreakMin;
  final int longBreakAfter;
  final double volume;
  final bool vibration;
  final bool notifications;

  const AppSettings({
    this.focusMin = 25,
    this.shortBreakMin = 5,
    this.longBreakMin = 15,
    this.longBreakAfter = 4,
    this.volume = 0.7,
    this.vibration = true,
    this.notifications = true,
  });

  AppSettings copyWith({
    int? focusMin,
    int? shortBreakMin,
    int? longBreakMin,
    int? longBreakAfter,
    double? volume,
    bool? vibration,
    bool? notifications,
  }) =>
      AppSettings(
        focusMin: focusMin ?? this.focusMin,
        shortBreakMin: shortBreakMin ?? this.shortBreakMin,
        longBreakMin: longBreakMin ?? this.longBreakMin,
        longBreakAfter: longBreakAfter ?? this.longBreakAfter,
        volume: volume ?? this.volume,
        vibration: vibration ?? this.vibration,
        notifications: notifications ?? this.notifications,
      );

  Map<String, dynamic> toMap() => {
        'focusMin': focusMin,
        'shortBreakMin': shortBreakMin,
        'longBreakMin': longBreakMin,
        'longBreakAfter': longBreakAfter,
        'volume': volume,
        'vibration': vibration,
        'notifications': notifications,
      };

  factory AppSettings.fromMap(Map<String, dynamic>? m) {
    const d = AppSettings();
    if (m == null) return d;
    return AppSettings(
      focusMin: (m['focusMin'] as num?)?.toInt() ?? d.focusMin,
      shortBreakMin: (m['shortBreakMin'] as num?)?.toInt() ?? d.shortBreakMin,
      longBreakMin: (m['longBreakMin'] as num?)?.toInt() ?? d.longBreakMin,
      longBreakAfter: (m['longBreakAfter'] as num?)?.toInt() ?? d.longBreakAfter,
      volume: (m['volume'] as num?)?.toDouble() ?? d.volume,
      vibration: m['vibration'] as bool? ?? d.vibration,
      notifications: m['notifications'] as bool? ?? d.notifications,
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String notes;
  final bool done;
  final DateTime createdAt;

  const TaskItem({
    required this.id,
    required this.title,
    this.notes = '',
    this.done = false,
    required this.createdAt,
  });

  factory TaskItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return TaskItem(
      id: doc.id,
      title: m['title'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      done: m['done'] as bool? ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// A finished focus session.
class StudySession {
  final String id;
  final String? taskId;
  final String? taskTitle;
  final DateTime endedAt;
  final int seconds;

  const StudySession({
    required this.id,
    this.taskId,
    this.taskTitle,
    required this.endedAt,
    required this.seconds,
  });

  int get minutes => (seconds / 60).round();

  factory StudySession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return StudySession(
      id: doc.id,
      taskId: m['taskId'] as String?,
      taskTitle: m['taskTitle'] as String?,
      endedAt: (m['endedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seconds: (m['seconds'] as num?)?.toInt() ?? 0,
    );
  }
}
