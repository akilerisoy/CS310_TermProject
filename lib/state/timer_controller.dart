import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/alert_service.dart';
import '../services/notification_service.dart';
import 'data_store.dart';

enum Phase { focus, shortBreak, longBreak }

/// The Pomodoro state machine.
///
/// The timer never counts ticks. While running it stores the wall-clock
/// moment the phase ends (`_endAt`), so it stays correct when the app is in
/// the background or killed: on resume the remaining time is recomputed and any
/// phase that finished meanwhile is completed (and its focus session saved).
class TimerController extends ChangeNotifier with WidgetsBindingObserver {
  TimerController({
    required this.data,
    required this.notifications,
    required this.alerts,
  }) {
    WidgetsBinding.instance.addObserver(this);
    data.addListener(_onDataChanged);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  final DataStore data;
  final NotificationService notifications;
  final AlertService alerts;

  late final Timer _ticker;
  SharedPreferences? _prefs;
  bool _inForeground = true;
  bool _disposed = false;

  Phase phase = Phase.focus;

  /// 1-based number of the focus session in the current cycle.
  int sessionInCycle = 1;
  bool running = false;
  String? taskId;

  DateTime? _endAt;
  int _remainingMs = 25 * 60 * 1000;
  int _phaseTotalSec = 25 * 60;
  bool _started = false; // phase has been started at least once

  // ---------- derived ----------

  int get cycleLength => data.settings.longBreakAfter;

  int secondsFor(Phase p) {
    final s = data.settings;
    switch (p) {
      case Phase.focus:
        return s.focusMin * 60;
      case Phase.shortBreak:
        return s.shortBreakMin * 60;
      case Phase.longBreak:
        return s.longBreakMin * 60;
    }
  }

  int get totalSeconds => _phaseTotalSec;

  int get remainingMs {
    if (running && _endAt != null) {
      final r = _endAt!.difference(DateTime.now()).inMilliseconds;
      return r < 0 ? 0 : r;
    }
    return _remainingMs;
  }

  int get remainingSeconds => (remainingMs / 1000).ceil();

  /// 0..1 of the phase that is still left.
  double get fractionLeft =>
      _phaseTotalSec == 0 ? 0 : (remainingMs / (_phaseTotalSec * 1000)).clamp(0.0, 1.0);

  bool get isBreak => phase != Phase.focus;

  /// A break that is not running but has been started (the "Paused" chip).
  bool get isPaused => !running && _started;

  String get title {
    switch (phase) {
      case Phase.focus:
        return 'Focus';
      case Phase.shortBreak:
        return 'Short break';
      case Phase.longBreak:
        return 'Long break';
    }
  }

  /// Number of focus sessions finished in the current cycle (for the dots).
  int get doneInCycle => isBreak ? sessionInCycle : sessionInCycle - 1;

  String get subtitle => isBreak
      ? '$sessionInCycle of $cycleLength done'
      : 'Session $sessionInCycle of $cycleLength';

  // ---------- actions ----------

  void toggle() {
    if (running) {
      _remainingMs = remainingMs;
      running = false;
      _endAt = null;
      notifications.cancelEnd();
    } else {
      _start(DateTime.now());
    }
    _changed();
  }

  void reset() {
    running = false;
    _started = false;
    _endAt = null;
    _phaseTotalSec = secondsFor(phase);
    _remainingMs = _phaseTotalSec * 1000;
    notifications.cancelEnd();
    _changed();
  }

  /// Jump to the next phase without saving anything.
  void skip() {
    final wasRunning = running;
    _moveToNext(DateTime.now(), autoStart: wasRunning);
    _changed();
  }

  void selectTask(String? id) {
    taskId = id;
    _changed();
  }

  // ---------- internals ----------

  void _start(DateTime from) {
    running = true;
    _started = true;
    _endAt = from.add(Duration(milliseconds: _remainingMs));
    _scheduleNotification();
  }

  void _moveToNext(DateTime at, {required bool autoStart}) {
    if (phase == Phase.focus) {
      // sessionInCycle stays: it is the number of the session just done.
    } else if (phase == Phase.longBreak) {
      sessionInCycle = 1;
    } else {
      sessionInCycle += 1;
    }
    phase = phase == Phase.focus
        ? (sessionInCycle >= cycleLength ? Phase.longBreak : Phase.shortBreak)
        : Phase.focus;
    _phaseTotalSec = secondsFor(phase);
    _remainingMs = _phaseTotalSec * 1000;
    _started = false;
    _endAt = null;
    running = false;
    notifications.cancelEnd();
    if (autoStart) _start(at);
  }

  void _completePhase(DateTime at, {required bool live}) {
    if (phase == Phase.focus) {
      final t = data.taskById(taskId);
      data.addSession(
        endedAt: at,
        seconds: _phaseTotalSec,
        taskId: t?.id,
        taskTitle: t?.title,
      );
    }
    if (live) {
      final s = data.settings;
      alerts.alert(volume: s.volume, vibration: s.vibration);
    }
    _moveToNext(at, autoStart: true);
  }

  void _tick() {
    if (_disposed) return;
    if (running && _endAt != null) {
      final now = DateTime.now();
      var guard = 0;
      var completed = false;
      while (running && _endAt != null && !now.isBefore(_endAt!) && guard < 100) {
        final end = _endAt!;
        // "live" = we are watching the timer reach zero right now.
        final live = _inForeground && now.difference(end).inSeconds < 2;
        _completePhase(end, live: live);
        completed = true;
        guard++;
      }
      if (completed) _persist();
      notifyListeners();
    }
  }

  String _endMessage() {
    final s = data.settings;
    switch (phase) {
      case Phase.focus:
        final next = sessionInCycle >= cycleLength ? s.longBreakMin : s.shortBreakMin;
        return 'Session $sessionInCycle of $cycleLength done. Time for a $next-minute break.';
      case Phase.shortBreak:
      case Phase.longBreak:
        final n = phase == Phase.longBreak ? 1 : sessionInCycle + 1;
        return 'Session $n of $cycleLength starts now. Back to focus!';
    }
  }

  String get _endTitle {
    switch (phase) {
      case Phase.focus:
        return 'Focus session finished';
      case Phase.shortBreak:
      case Phase.longBreak:
        return 'Break is over';
    }
  }

  void _scheduleNotification() {
    if (!data.settings.notifications || _endAt == null) {
      notifications.cancelEnd();
      return;
    }
    notifications.scheduleEnd(_endAt!, _endTitle, _endMessage());
  }

  void _onDataChanged() {
    // Settings can change the length of a phase that has not been started.
    final fresh = secondsFor(phase);
    if (!_started && !running && fresh != _phaseTotalSec) {
      _phaseTotalSec = fresh;
      _remainingMs = fresh * 1000;
    }
    if (sessionInCycle > cycleLength) sessionInCycle = cycleLength;
    // A task that was deleted or marked done can no longer be selected.
    final t = data.taskById(taskId);
    if (taskId != null && (t == null || t.done)) taskId = null;
    if (running) _scheduleNotification();
    notifyListeners();
  }

  void _changed() {
    _persist();
    notifyListeners();
  }

  // ---------- persistence (survives the app being closed) ----------

  String get _key => 'timer_${data.uid}';

  Future<void> restore() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getStringList(_key);
    if (raw == null || raw.length < 8) return;
    try {
      phase = Phase.values[int.parse(raw[0])];
      sessionInCycle = int.parse(raw[1]);
      running = raw[2] == '1';
      _endAt = raw[3].isEmpty ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(raw[3]));
      _remainingMs = int.parse(raw[4]);
      _phaseTotalSec = int.parse(raw[5]);
      _started = raw[6] == '1';
      taskId = raw[7].isEmpty ? null : raw[7];
      if (running && _endAt == null) running = false;
    } catch (_) {
      return;
    }
    _tick(); // catch up with phases that ended while the app was closed
    notifyListeners();
  }

  void _persist() {
    final p = _prefs;
    if (p == null) return;
    p.setStringList(_key, [
      '${phase.index}',
      '$sessionInCycle',
      running ? '1' : '0',
      _endAt == null ? '' : '${_endAt!.millisecondsSinceEpoch}',
      '$_remainingMs',
      '$_phaseTotalSec',
      _started ? '1' : '0',
      taskId ?? '',
    ]);
  }

  // ---------- lifecycle ----------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (_inForeground) {
      // Anything that ended while we were away is not "live": no sound.
      _tick();
      notifyListeners();
    }
  }

  /// Stops everything (used on log out).
  Future<void> shutdown() async {
    running = false;
    _endAt = null;
    await notifications.cancelAll();
    await _prefs?.remove(_key);
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.cancel();
    WidgetsBinding.instance.removeObserver(this);
    data.removeListener(_onDataChanged);
    super.dispose();
  }
}
