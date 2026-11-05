import 'package:flutter/material.dart';

/// Theme-aware palette used across SpendTrack.
///
/// The palette is resolved from the active [ThemeData.brightness] instead of a
/// global mutable value, so every widget automatically receives the correct
/// colours when the user switches between light and dark mode.
@immutable
class AppPalette {
  const AppPalette({
    required this.brand,
    required this.brandDeep,
    required this.navy,
    required this.navySoft,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.background,
    required this.surface,
    required this.field,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.shadow,
    required this.isDark,
  });

  /// Dark brand colour used behind white text (hero cards, primary actions).
  final Color brand;

  /// Deepest brand colour used for hero gradients.
  final Color brandDeep;

  /// Backwards-compatible name for the deep brand gradient endpoint.
  Color get navyDeep => brandDeep;

  /// Strong foreground colour for amounts, titles, and selected controls.
  final Color navy;

  /// Slightly softer strong foreground used on tinted surfaces.
  final Color navySoft;

  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color background;
  final Color surface;
  final Color field;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color warning;
  final Color shadow;
  final bool isDark;

  static const AppPalette light = AppPalette(
    brand: Color(0xFF0B1F3A),
    brandDeep: Color(0xFF06152A),
    navy: Color(0xFF0B1F3A),
    navySoft: Color(0xFF18365D),
    accent: Color(0xFF2F6BFF),
    accentDark: Color(0xFF1F4FD8),
    accentSoft: Color(0xFFE9F0FF),
    background: Color(0xFFF3F6FC),
    surface: Colors.white,
    field: Color(0xFFF7F9FE),
    border: Color(0xFFE7EDF6),
    borderStrong: Color(0xFFD5DEEB),
    textPrimary: Color(0xFF11294A),
    textSecondary: Color(0xFF687B93),
    textMuted: Color(0xFF98A6B8),
    success: Color(0xFF0FA97A),
    successSoft: Color(0xFFE7F8F2),
    danger: Color(0xFFE5484D),
    dangerSoft: Color(0xFFFDECEC),
    warning: Color(0xFFF3A322),
    shadow: Color(0xFF0B1F3A),
    isDark: false,
  );

  static const AppPalette dark = AppPalette(
    brand: Color(0xFF1B355C),
    brandDeep: Color(0xFF0A1729),
    navy: Color(0xFFE8EFFB),
    navySoft: Color(0xFFC2D0E5),
    accent: Color(0xFF6E9BFF),
    accentDark: Color(0xFFA9C3FF),
    accentSoft: Color(0xFF1A2E50),
    background: Color(0xFF0A1120),
    surface: Color(0xFF111B2D),
    field: Color(0xFF172337),
    border: Color(0xFF223049),
    borderStrong: Color(0xFF30415D),
    textPrimary: Color(0xFFEDF2FB),
    textSecondary: Color(0xFFA3B3C9),
    textMuted: Color(0xFF7386A1),
    success: Color(0xFF3DDBA4),
    successSoft: Color(0xFF11352A),
    danger: Color(0xFFFF7275),
    dangerSoft: Color(0xFF3A1B20),
    warning: Color(0xFFF6BC5C),
    shadow: Colors.black,
    isDark: true,
  );

  /// Resolves the palette for the current theme brightness.
  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
  }
}

/// Convenience accessor: `context.palette.accent`.
extension AppPaletteContext on BuildContext {
  AppPalette get palette => AppPalette.of(this);
}
