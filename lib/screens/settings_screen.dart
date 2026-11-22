import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../state/data_store.dart';
import '../state/timer_controller.dart';
import '../theme.dart';

/// S12 Settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataStore>();
    final s = data.settings;

    Widget section(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 4),
          child: Text(t, style: const TextStyle(color: kMuted, fontSize: 12)),
        );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          const Text('Settings',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kInk)),
          section('Timer'),
          _Stepper(
            label: 'Focus',
            value: s.focusMin,
            unit: 'min',
            min: 5,
            max: 90,
            step: 5,
            onChanged: (v) => data.saveSettings(s.copyWith(focusMin: v)),
          ),
          _Stepper(
            label: 'Short break',
            value: s.shortBreakMin,
            unit: 'min',
            min: 1,
            max: 30,
            step: 1,
            onChanged: (v) => data.saveSettings(s.copyWith(shortBreakMin: v)),
          ),
          _Stepper(
            label: 'Long break',
            value: s.longBreakMin,
            unit: 'min',
            min: 5,
            max: 60,
            step: 5,
            onChanged: (v) => data.saveSettings(s.copyWith(longBreakMin: v)),
          ),
          _Stepper(
            label: 'Long break after',
            value: s.longBreakAfter,
            unit: 'sessions',
            min: 2,
            max: 8,
            step: 1,
            onChanged: (v) => data.saveSettings(s.copyWith(longBreakAfter: v)),
          ),
          section('Sound and alerts'),
          Row(children: [
            const Text('Volume'),
            const SizedBox(width: 16),
            const Icon(Icons.volume_down, size: 18, color: kMuted),
            Expanded(
              child: Slider(
                value: s.volume,
                onChanged: (v) => data.saveSettings(s.copyWith(volume: v)),
                onChangeEnd: (v) => context.read<AlertService>().playSound(v),
              ),
            ),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vibration'),
            value: s.vibration,
            onChanged: (v) {
              data.saveSettings(s.copyWith(vibration: v));
              if (v) context.read<AlertService>().vibrate();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifications'),
            value: s.notifications,
            onChanged: (v) {
              data.saveSettings(s.copyWith(notifications: v));
              if (v) context.read<NotificationService>().requestPermission();
            },
          ),
          section('Account'),
          Text(data.name.isEmpty ? 'Signed in' : data.name,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(data.email, style: const TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
                foregroundColor: kInk, alignment: Alignment.centerLeft),
            icon: const Icon(Icons.logout),
            label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () async {
              final timer = context.read<TimerController>();
              final auth = context.read<AuthService>();
              await timer.shutdown();
              await auth.logOut();
            },
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });
  final String label, unit;
  final int value, min, max, step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kSoft))),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: 'Decrease $label',
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value - step >= min ? () => onChanged(value - step) : null,
        ),
        SizedBox(
          width: 84,
          child: Text('$value $unit',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        IconButton(
          tooltip: 'Increase $label',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value + step <= max ? () => onChanged(value + step) : null,
        ),
      ]),
    );
  }
}
