import 'package:material_ui/material_ui.dart';

/// Shared spacing values so every screen uses the same rhythm.
/// Colors and text styles live in theme.dart.
class Spacing {
  Spacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 40;

  /// Horizontal page margin used by all screens.
  static const double page = 24;

  /// Corner radius of cards, boxes and input fields.
  static const double radius = 10;

  /// Padding of a full-page scrolling screen (Settings, Stats).
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(page, lg, page, page);

  /// Padding of a page whose bottom is handled by its list (Timer, Tasks).
  static const EdgeInsets pageTop = EdgeInsets.fromLTRB(page, lg, page, 0);

  /// Padding inside info boxes and cards.
  static const EdgeInsets box = EdgeInsets.all(14);
}
