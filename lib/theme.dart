import 'package:material_ui/material_ui.dart';

import 'spacing.dart';

const kInk = Color(0xFF3F3F3F);
const kMuted = Color(0xFF777777);
const kLine = Color(0xFFD0D0D0);
const kTrack = Color(0xFFE3E3E3);
const kSoft = Color(0xFFF1F1F1);

/// Custom font bundled in assets/fonts and registered in pubspec.yaml.
const kFontFamily = 'Poppins';

/// Shared text styles used across screens.
class AppText {
  AppText._();

  /// Big heading at the top of each tab (Tasks, Stats, Settings).
  static const pageTitle = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kInk);

  /// Small grey label above a field or inside a box.
  static const label = TextStyle(color: kMuted, fontSize: 12);

  /// Grey helper text.
  static const muted = TextStyle(color: kMuted);

  /// Bold body text (task titles, values).
  static const strong = TextStyle(fontWeight: FontWeight.w700);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kInk,
    brightness: Brightness.light,
  ).copyWith(
    primary: kInk,
    onPrimary: Colors.white,
    surface: Colors.white,
    error: const Color(0xFF3F3F3F),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: kFontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Spacing.radius),
        borderSide: const BorderSide(color: kLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Spacing.radius),
        borderSide: const BorderSide(color: kLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Spacing.radius),
        borderSide: const BorderSide(color: kInk, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Spacing.radius),
        borderSide: const BorderSide(color: kInk),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Spacing.radius),
        borderSide: const BorderSide(color: kInk, width: 1.6),
      ),
      errorStyle: const TextStyle(color: kInk, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kInk,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: const StadiumBorder(),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kTrack,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: kInk),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kInk : kLine,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: kInk,
      inactiveTrackColor: kTrack,
      thumbColor: kInk,
    ),
  );
}

/// Formats minutes as "50 min" or "5 h 50 min".
String fmtMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

String fmtClock(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
