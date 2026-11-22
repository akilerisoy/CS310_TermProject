import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Live copy of the signed-in user's Firestore data:
/// users/{uid}  (profile + settings), users/{uid}/tasks, users/{uid}/sessions.
class DataStore extends ChangeNotifier {
  final String uid;
  final String name;
  final String email;

  DataStore({required this.uid, required this.name, required this.email}) {
    _listen();
  }

  final _db = FirebaseFirestore.instance;
  final List<StreamSubscription> _subs = [];

  AppSettings settings = const AppSettings();
  List<TaskItem> tasks = [];
  List<StudySession> sessions = [];
  bool loaded = false;
  Object? error;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _tasks =>
      _userDoc.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _sessions =>
      _userDoc.collection('sessions');

  void _listen() {
    void onError(Object e) {
      error = e;
      notifyListeners();
    }

    _subs.add(_userDoc.snapshots().listen((s) {
      settings = AppSettings.fromMap(s.data()?['settings'] as Map<String, dynamic>?);
      loaded = true;
      notifyListeners();
    }, onError: onError));

    _subs.add(_tasks.orderBy('createdAt').snapshots().listen((s) {
      tasks = s.docs.map(TaskItem.fromDoc).toList();
      notifyListeners();
    }, onError: onError));

    _subs.add(_sessions.orderBy('endedAt', descending: true).snapshots().listen((s) {
      sessions = s.docs.map(StudySession.fromDoc).toList();
      notifyListeners();
    }, onError: onError));
  }

  // ---- derived data ----

  List<TaskItem> get todoTasks => tasks.where((t) => !t.done).toList();
  List<TaskItem> get doneTasks => tasks.where((t) => t.done).toList();

  TaskItem? taskById(String? id) {
    if (id == null) return null;
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<StudySession> sessionsOf(String taskId) =>
      sessions.where((s) => s.taskId == taskId).toList();

  int secondsOf(String taskId) =>
      sessionsOf(taskId).fold(0, (total, s) => total + s.seconds);

  // ---- writes ----

  /// Returns the id of the new task.
  Future<String> addTask(String title, String notes, bool done) async {
    final ref = _tasks.doc();
    await ref.set({
      'title': title.trim(),
      'notes': notes.trim(),
      'done': done,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateTask(String id,
      {required String title, required String notes, required bool done}) {
    return _tasks.doc(id).update({
      'title': title.trim(),
      'notes': notes.trim(),
      'done': done,
    });
  }

  Future<void> setTaskDone(String id, bool done) =>
      _tasks.doc(id).update({'done': done});

  Future<void> deleteTask(String id) => _tasks.doc(id).delete();

  Future<void> addSession({
    required DateTime endedAt,
    required int seconds,
    String? taskId,
    String? taskTitle,
  }) {
    return _sessions.add({
      'endedAt': Timestamp.fromDate(endedAt),
      'seconds': seconds,
      'taskId': taskId,
      'taskTitle': taskTitle,
    });
  }

  Future<void> saveSettings(AppSettings s) {
    settings = s; // optimistic, the snapshot confirms it
    notifyListeners();
    return _userDoc.set({'settings': s.toMap()}, SetOptions(merge: true));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
