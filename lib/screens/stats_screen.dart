import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../spacing.dart';
import '../state/data_store.dart';
import '../theme.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// S11 Stats and history. Everything is calculated from saved sessions.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<DataStore>().sessions;
    final today = _day(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));

    final perDay = List<int>.filled(7, 0); // seconds, Monday first
    var todaySec = 0, todayCount = 0, weekSec = 0, weekCount = 0;
    for (final s in sessions) {
      final d = _day(s.endedAt);
      if (d == today) {
        todaySec += s.seconds;
        todayCount++;
      }
      if (!d.isBefore(monday) && d.isBefore(nextMonday)) {
        weekSec += s.seconds;
        weekCount++;
        perDay[d.weekday - 1] += s.seconds;
      }
    }
    final perDayMin = perDay.map((s) => (s / 60).round()).toList();

    // History grouped by day, newest first (sessions are already sorted).
    final groups = <DateTime, List<StudySession>>{};
    for (final s in sessions.take(200)) {
      groups.putIfAbsent(_day(s.endedAt), () => []).add(s);
    }

    String label(DateTime d) {
      if (d == today) return 'Today';
      if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return DateFormat('EEEE, d MMMM').format(d);
    }

    return SafeArea(
      child: ListView(
        padding: Spacing.pagePadding,
        children: [
          const Text('Stats',
              style: AppText.pageTitle),
          const SizedBox(height: Spacing.md),
          Row(children: [
            Expanded(
                child: _StatCard(
                    title: 'Today',
                    value: fmtMinutes((todaySec / 60).round()),
                    sub: '$todayCount session${todayCount == 1 ? '' : 's'}')),
            const SizedBox(width: Spacing.md),
            Expanded(
                child: _StatCard(
                    title: 'This week',
                    value: fmtMinutes((weekSec / 60).round()),
                    sub: '$weekCount session${weekCount == 1 ? '' : 's'}')),
          ]),
          const SizedBox(height: Spacing.md),
          _WeekChart(minutes: perDayMin, todayIndex: today.weekday - 1),
          const SizedBox(height: Spacing.lg),
          const Text('History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
          const SizedBox(height: Spacing.xs),
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No finished sessions yet. Complete a focus session on the timer.',
                  style: AppText.muted),
            ),
          for (final e in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(label(e.key), style: AppText.label),
            ),
            for (final s in e.value)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: kSoft)),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 56,
                    child: Text(DateFormat('HH:mm').format(s.endedAt),
                        style: AppText.muted),
                  ),
                  Expanded(
                    child: Text(s.taskTitle ?? 'No task',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: s.taskTitle == null ? kMuted : kInk)),
                  ),
                  Text('${s.minutes} min', style: AppText.muted),
                ]),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.sub});
  final String title, value, sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Spacing.box,
      decoration: BoxDecoration(
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppText.label),
        const SizedBox(height: Spacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
        ),
        Text(sub, style: const TextStyle(color: kMuted, fontSize: 11)),
      ]),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.minutes, required this.todayIndex});
  final List<int> minutes;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxV = minutes.fold<int>(0, (a, b) => b > a ? b : a);
    const maxBar = 110.0;
    return Container(
      padding: Spacing.box,
      decoration: BoxDecoration(
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Minutes studied per day',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: Spacing.sm),
        SizedBox(
          height: maxBar + 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(minutes[i] > 0 ? '${minutes[i]}' : '',
                          style: const TextStyle(fontSize: 10, color: kMuted)),
                      const SizedBox(height: Spacing.xxs),
                      Container(
                        width: 22,
                        height: maxV == 0 ? 3 : (minutes[i] / maxV * maxBar).clamp(3.0, maxBar),
                        decoration: BoxDecoration(
                          color: i == todayIndex ? kInk : kLine,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(days[i],
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == todayIndex ? FontWeight.w800 : FontWeight.w400,
                              color: kInk)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
