import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../spacing.dart';
import '../state/data_store.dart';
import '../state/timer_controller.dart';
import '../theme.dart';
import 'task_edit_screen.dart';

/// S9 Tasks.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool showDone = false;

  String _subtitle(DataStore data, TaskItem t) {
    final n = data.sessionsOf(t.id).length;
    if (n == 0) return 'No sessions yet';
    final mins = (data.secondsOf(t.id) / 60).round();
    return '$n session${n == 1 ? '' : 's'}, $mins min';
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataStore>();
    final timer = context.watch<TimerController>();
    final list = showDone ? data.doneTasks : data.todoTasks;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kInk,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
        onPressed: () => TaskEditScreen.open(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: Spacing.pageTop,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tasks', style: AppText.pageTitle),
              const SizedBox(height: Spacing.md),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: kTrack,
                    selectedForegroundColor: kInk,
                    foregroundColor: kInk,
                  ),
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text('To do ${data.todoTasks.length}'),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Done ${data.doneTasks.length}'),
                    ),
                  ],
                  selected: {showDone},
                  onSelectionChanged: (s) => setState(() => showDone = s.first),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          showDone
                              ? 'No finished tasks yet.'
                              : 'No tasks yet. Tap "Add task".',
                          style: AppText.muted,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(
                          top: Spacing.xs,
                          bottom: 90,
                        ),
                        itemCount: list.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Spacing.sm),
                        itemBuilder: (context, i) {
                          final t = list[i];
                          final onTimer = timer.taskId == t.id;
                          return Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: kInk,
                                borderRadius: BorderRadius.circular(
                                  Spacing.radius,
                                ),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => data.deleteTask(t.id),
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Spacing.radius,
                                ),
                                side: const BorderSide(color: kLine),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(
                                  left: Spacing.xs,
                                ),
                                leading: IconButton(
                                  tooltip: t.done
                                      ? 'Mark as to do'
                                      : 'Mark as done',
                                  icon: Icon(
                                    t.done
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                  ),
                                  color: kInk,
                                  onPressed: () =>
                                      data.setTaskDone(t.id, !t.done),
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          decoration: t.done
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (onTimer) ...[
                                      const SizedBox(width: Spacing.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: kInk),
                                          borderRadius: BorderRadius.circular(
                                            Spacing.radius,
                                          ),
                                        ),
                                        child: const Text(
                                          'On timer',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  _subtitle(data, t),
                                  style: AppText.label,
                                ),
                                trailing: IconButton(
                                  tooltip: 'Remove task',
                                  icon: const Icon(Icons.delete_outline),
                                  color: kInk,
                                  onPressed: () => data.deleteTask(t.id),
                                ),
                                onTap: () =>
                                    TaskEditScreen.open(context, task: t),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
