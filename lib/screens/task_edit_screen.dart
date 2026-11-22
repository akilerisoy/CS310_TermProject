import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../spacing.dart';
import '../state/data_store.dart';
import '../theme.dart';

/// S10 Add or edit task. Pops with the id of the saved task.
class TaskEditScreen extends StatefulWidget {
  const TaskEditScreen({super.key, this.task});
  final TaskItem? task;

  /// Opens the form. New routes sit above the per-user providers created in
  /// main.dart, so the DataStore is passed along to the new route.
  static Future<String?> open(BuildContext context,
      {TaskItem? task, bool fullscreenDialog = false}) {
    final data = context.read<DataStore>();
    return Navigator.of(context).push<String>(MaterialPageRoute(
      fullscreenDialog: fullscreenDialog,
      builder: (_) => ChangeNotifierProvider<DataStore>.value(
        value: data,
        child: TaskEditScreen(task: task),
      ),
    ));
  }

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late final title = TextEditingController(text: widget.task?.title ?? '');
  late final notes = TextEditingController(text: widget.task?.notes ?? '');
  late bool done = widget.task?.done ?? false;
  String? titleError;
  bool saving = false;

  bool get isEdit => widget.task != null;

  Future<void> save() async {
    if (title.text.trim().isEmpty) {
      setState(() => titleError = 'Title is required.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Save changes?' : 'Add this task?'),
        content: Text('"${title.text.trim()}"'
            '${done ? ' will be marked as done.' : ' will be in your to do list.'}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Save' : 'Add')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => saving = true);
    final data = context.read<DataStore>();
    final nav = Navigator.of(context);
    String id;
    if (isEdit) {
      id = widget.task!.id;
      data.updateTask(id, title: title.text, notes: notes.text, done: done);
    } else {
      id = await data.addTask(title.text, notes.text, done);
    }
    nav.pop(id);
  }

  Future<void> delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('Study sessions already recorded for it stay in your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final data = context.read<DataStore>();
    final nav = Navigator.of(context);
    data.deleteTask(widget.task!.id);
    nav.pop();
  }

  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataStore>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: Text(isEdit ? 'Edit task' : 'New task',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: saving ? null : save,
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.w800, color: kInk)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.page),
          children: [
            const Text('Title', style: AppText.label),
            const SizedBox(height: Spacing.xs),
            TextField(
              controller: title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(errorText: titleError),
              onChanged: (_) {
                if (titleError != null) setState(() => titleError = null);
              },
            ),
            const SizedBox(height: Spacing.lg),
            const Text('Notes (optional)', style: AppText.label),
            const SizedBox(height: Spacing.xs),
            TextField(
              controller: notes,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Spacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mark as done'),
              value: done,
              onChanged: (v) => setState(() => done = v),
            ),
            if (isEdit) ...[
              const Divider(height: 1, color: kSoft),
              const SizedBox(height: Spacing.md),
              Container(
                padding: Spacing.box,
                decoration: BoxDecoration(
                  color: kSoft,
                  borderRadius: BorderRadius.circular(Spacing.radius),
                ),
                child: Row(children: [
                  const Text('Time spent', style: AppText.muted),
                  const Spacer(),
                  Text(
                    () {
                      final n = data.sessionsOf(widget.task!.id).length;
                      final m = (data.secondsOf(widget.task!.id) / 60).round();
                      return '$n session${n == 1 ? '' : 's'}, $m min';
                    }(),
                    style: AppText.strong,
                  ),
                ]),
              ),
              const SizedBox(height: Spacing.xxxl),
              OutlinedButton.icon(
                onPressed: delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete task'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kInk,
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: kInk),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
