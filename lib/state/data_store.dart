import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Live copy of the signed-in user's Firestore data:
/// users/{uid}  (profile + settings), users/{uid}/tasks, users/{uid}/sessions.
///
/// With [demo] set (Firebase not configured) it keeps placeholder data in
/// memory instead, so the whole UI can be tried without a backend.
class DataStore extends ChangeNotifier {
  final String uid;
  final String name;
  final String email;
  final bool demo;

  DataStore({
    required this.uid,
    required this.name,
    required this.email,
    this.demo = false,
  }) {
    if (demo) {
      _loadPlaceholders();
    } else {
      _listen();
    }
  }

  // A getter, so Firestore is never touched in demo mode.
  FirebaseFirestore get _db => FirebaseFirestore.instance;
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

  void _loadPlaceholders() {
    final now = DateTime.now();
    tasks = [
      TaskItem(id: 'demo1', title: 'CS310 Step 2 UI', notes: 'Build the screens from the wireframes.', createdAt: now.subtract(const Duration(days: 3))),
      TaskItem(id: 'demo2', title: 'MATH201 problem set', notes: 'Questions 1 to 8.', createdAt: now.subtract(const Duration(days: 2))),
      TaskItem(id: 'demo3', title: 'Read chapter 4', createdAt: now.subtract(const Duration(days: 1))),
      TaskItem(id: 'demo4', title: 'Prepare presentation slides', done: true, createdAt: now.subtract(const Duration(days: 4))),
    ];
    sessions = [
      StudySession(id: 's1', taskId: 'demo1', taskTitle: 'CS310 Step 2 UI', endedAt: now.subtract(const Duration(hours: 2)), seconds: 25 * 60),
      StudySession(id: 's2', taskId: 'demo1', taskTitle: 'CS310 Step 2 UI', endedAt: now.subtract(const Duration(hours: 3)), seconds: 25 * 60),
      StudySession(id: 's3', taskId: 'demo2', taskTitle: 'MATH201 problem set', endedAt: now.subtract(const Duration(days: 1, hours: 1)), seconds: 25 * 60),
      StudySession(id: 's4', taskId: 'demo4', taskTitle: 'Prepare presentation slides', endedAt: now.subtract(const Duration(days: 2)), seconds: 50 * 60),
    ];
    loaded = true;
  }

  int _nextId = 0;
  String _demoId() => 'local${_nextId++}';

  TaskItem _copyTask(TaskItem t, {String? title, String? notes, bool? done}) => TaskItem(
        id: t.id,
        title: title ?? t.title,
        notes: notes ?? t.notes,
        done: done ?? t.done,
        createdAt: t.createdAt,
      );

  void _demoUpdate(String id, TaskItem Function(TaskItem) f) {
    tasks = [for (final t in tasks) t.id == id ? f(t) : t];
    notifyListeners();
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
    if (demo) {
      final id = _demoId();
      tasks = [...tasks, TaskItem(id: id, title: title.trim(), notes: notes.trim(), done: done, createdAt: DateTime.now())];
      notifyListeners();
      return id;
    }
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
      {required String title, required String notes, required bool done}) async {
    if (demo) {
      return _demoUpdate(id, (t) => _copyTask(t, title: title.trim(), notes: notes.trim(), done: done));
    }
    return _tasks.doc(id).update({
      'title': title.trim(),
      'notes': notes.trim(),
      'done': done,
    });
  }

  Future<void> setTaskDone(String id, bool done) async {
    if (demo) return _demoUpdate(id, (t) => _copyTask(t, done: done));
    return _tasks.doc(id).update({'done': done});
  }

  Future<void> deleteTask(String id) async {
    if (demo) {
      tasks = tasks.where((t) => t.id != id).toList();
      return notifyListeners();
    }
    return _tasks.doc(id).delete();
  }

  Future<void> addSession({
    required DateTime endedAt,
    required int seconds,
    String? taskId,
    String? taskTitle,
  }) async {
    if (demo) {
      sessions = [
        StudySession(id: _demoId(), taskId: taskId, taskTitle: taskTitle, endedAt: endedAt, seconds: seconds),
        ...sessions,
      ];
      return notifyListeners();
    }
    await _sessions.add({
      'endedAt': Timestamp.fromDate(endedAt),
      'seconds': seconds,
      'taskId': taskId,
      'taskTitle': taskTitle,
    });
  }

  Future<void> saveSettings(AppSettings s) {
    settings = s; // optimistic, the snapshot confirms it
    notifyListeners();
    if (demo) return Future.value();
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
