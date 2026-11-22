import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../spacing.dart';
import '../state/data_store.dart';
import '../state/timer_controller.dart';
import '../theme.dart';
import 'task_edit_screen.dart';

/// S5 Timer and S6 Timer on a break (same screen, different phase).
class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TimerController>();
    final data = context.watch<DataStore>();
    final task = data.taskById(t.taskId);

    return SafeArea(
      child: LayoutBuilder(builder: (context, box) {
        final ring = math.min(box.maxWidth - 72, box.maxHeight * 0.42).clamp(180.0, 320.0);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.page, vertical: Spacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: kInk)),
                  const SizedBox(height: Spacing.sm),
                  _Dots(t),
                  const SizedBox(height: Spacing.xl),
                  SizedBox(
                    width: ring,
                    height: ring,
                    child: CustomPaint(
                      painter: _RingPainter(t.fractionLeft),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(fmtClock(t.remainingSeconds),
                                style: TextStyle(
                                    fontSize: ring * 0.26,
                                    fontWeight: FontWeight.w300,
                                    color: kInk,
                                    fontFeatures: const [FontFeature.tabularFigures()])),
                            Text('of ${fmtClock(t.totalSeconds)}',
                                style: AppText.label),
                            if (t.isBreak && t.isPaused)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: kInk),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Paused',
                                    style: TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xxl),
                  _TaskCard(t: t, taskTitle: task?.title),
                  const SizedBox(height: Spacing.xxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoundButton(
                        icon: Icons.replay,
                        label: 'Reset',
                        onTap: t.reset,
                      ),
                      const SizedBox(width: 28),
                      _RoundButton(
                        icon: t.running ? Icons.pause : Icons.play_arrow,
                        label: t.running ? 'Pause' : (t.isPaused ? 'Resume' : 'Start'),
                        onTap: t.toggle,
                        big: true,
                      ),
                      const SizedBox(width: 28),
                      _RoundButton(
                        icon: Icons.skip_next,
                        label: 'Skip',
                        onTap: t.skip,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots(this.t);
  final TimerController t;

  @override
  Widget build(BuildContext context) {
    final n = t.cycleLength;
    final done = t.doneInCycle;
    final dots = <Widget>[];
    for (var i = 0; i < n; i++) {
      final Widget d;
      if (i < done) {
        d = const Icon(Icons.circle, size: 11, color: kInk);
      } else if (i == done && !t.isBreak) {
        d = const Icon(Icons.contrast, size: 11, color: kInk);
      } else {
        d = const Icon(Icons.circle_outlined, size: 11, color: kInk);
      }
      dots.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: d));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...dots,
        const SizedBox(width: Spacing.sm),
        Text(t.subtitle, style: AppText.label),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = kTrack;
    canvas.drawArc(r, 0, math.pi * 2, false, track);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = kInk;
    if (fraction > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * fraction, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.t, required this.taskTitle});
  final TimerController t;
  final String? taskTitle;

  @override
  Widget build(BuildContext context) {
    final label = taskTitle ?? 'No task';
    if (t.isBreak) {
      final next = t.phase == Phase.longBreak ? 1 : t.sessionInCycle + 1;
      return Container(
        width: double.infinity,
        padding: Spacing.box,
        decoration: BoxDecoration(
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Up next: session $next of ${t.cycleLength}',
              style: AppText.label),
          const SizedBox(height: Spacing.xxs),
          Text(label, style: AppText.strong),
        ]),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Task for this session',
                style: AppText.label),
            const SizedBox(height: Spacing.xxs),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.strong),
          ]),
        ),
        TextButton(
          onPressed: () => chooseTask(context),
          child: const Text('Change',
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w700,
                  color: kInk)),
        ),
      ]),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.big = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 68.0 : 50.0;
    return Column(children: [
      Material(
        color: big ? kInk : Colors.white,
        shape: CircleBorder(side: BorderSide(color: big ? kInk : kMuted)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: big ? Colors.white : kInk, size: big ? 32 : 22),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: kInk)),
    ]);
  }
}

/// S7 Choose a task (bottom sheet).
Future<void> chooseTask(BuildContext context) async {
  final timer = context.read<TimerController>();
  final data = context.read<DataStore>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetCtx) {
      String? selected = timer.taskId;
      return StatefulBuilder(builder: (ctx, setSheet) {
        final todo = data.todoTasks;
        return SafeArea(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.page, 0, Spacing.page, Spacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose a task',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Text('Time from this session will count toward it.',
                      style: AppText.label),
                  const SizedBox(height: Spacing.sm),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final task in todo)
                          _TaskOption(
                            label: task.title,
                            selected: selected == task.id,
                            onTap: () => setSheet(() => selected = task.id),
                          ),
                        _TaskOption(
                          label: 'No task',
                          muted: true,
                          selected: selected == null,
                          onTap: () => setSheet(() => selected = null),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.add, color: kInk),
                          title: const Text('New task',
                              style: AppText.strong),
                          onTap: () async {
                            Navigator.pop(sheetCtx);
                            final id = await TaskEditScreen.open(context,
                                fullscreenDialog: true);
                            if (id != null) timer.selectTask(id);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  FilledButton(
                    onPressed: () {
                      timer.selectTask(selected);
                      Navigator.pop(sheetCtx);
                    },
                    child: const Text('Use this task'),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}

class _TaskOption extends StatelessWidget {
  const _TaskOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });
  final String label;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kSoft)),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: muted && !selected ? kMuted : kInk),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(label,
                style: TextStyle(color: muted ? kMuted : kInk),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}
