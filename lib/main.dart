import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth_screens.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/timer_screen.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'state/data_store.dart';
import 'state/timer_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseError;
  try {
    if (DefaultFirebaseOptions.isPlaceholder) {
      throw StateError('Firebase is not configured yet. Run "flutterfire configure" '
          '(see README.md), then start the app again.');
    }
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    firebaseError = e.toString();
  }

  final notifications = NotificationService();
  await notifications.init();

  runApp(MultiProvider(
    providers: [
      Provider<NotificationService>.value(value: notifications),
      Provider<AlertService>(
        create: (_) => AlertService(),
        dispose: (_, a) => a.dispose(),
      ),
      if (firebaseError == null) Provider<AuthService>(create: (_) => AuthService()),
    ],
    child: PomodoroApp(firebaseError: firebaseError),
  ));
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key, this.firebaseError});
  final String? firebaseError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: firebaseError != null
          ? _SetupError(message: firebaseError!)
          : const _AuthGate(),
    );
  }
}

class _SetupError extends StatelessWidget {
  const _SetupError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      );
}

/// S1: splash until Firebase tells us whether someone is logged in, then
/// either the app (logged in) or the log in flow.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.userChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snap.data;
        if (user == null) return AuthFlow(auth: auth);
        return _SignedIn(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

/// Creates the per-user state (Firestore data and timer) once per login.
class _SignedIn extends StatefulWidget {
  const _SignedIn({super.key, required this.user});
  final User user;

  @override
  State<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends State<_SignedIn> {
  late final DataStore data = DataStore(
    uid: widget.user.uid,
    name: widget.user.displayName ?? '',
    email: widget.user.email ?? '',
  );
  late final TimerController timer = TimerController(
    data: data,
    notifications: context.read<NotificationService>(),
    alerts: context.read<AlertService>(),
  );

  @override
  void initState() {
    super.initState();
    final notifs = context.read<NotificationService>();
    timer.restore();
    notifs.requestPermission();
  }

  @override
  void dispose() {
    timer.dispose();
    data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataStore>.value(value: data),
        ChangeNotifierProvider<TimerController>.value(value: timer),
      ],
      child: const HomeShell(),
    );
  }
}

/// Bottom navigation between Timer (S5), Tasks (S9), Stats (S11), Settings (S12).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  static const _pages = <Widget>[
    TimerScreen(),
    TasksScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final error = context.select<DataStore, Object?>((d) => d.error);
    return Scaffold(
      body: Column(
        children: [
          if (error != null)
            Material(
              color: kSoft,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Could not sync with the server: $error',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
          Expanded(child: IndexedStack(index: index, children: _pages)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Timer'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}
