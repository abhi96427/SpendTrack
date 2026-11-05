import 'app_currency.dart';

/// Theme choices offered in the settings screen.
enum AppThemeMode {
  light('Light'),
  dark('Dark');

  const AppThemeMode(this.label);

  final String label;

  static AppThemeMode fromName(String? name) {
    for (final mode in values) {
      if (mode.name == name) {
        return mode;
      }
    }
    return AppThemeMode.light;
  }
}

/// User preferences persisted alongside the expense database.
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.light,
    this.currency = AppCurrency.inr,
  });

  /// INR and the light theme are the defaults for a fresh install.
  static const AppSettings defaults = AppSettings();

  final AppThemeMode themeMode;
  final AppCurrency currency;

  AppSettings copyWith({AppThemeMode? themeMode, AppCurrency? currency}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
    );
  }

  Map<String, String> toMap() {
    return <String, String>{
      'theme_mode': themeMode.name,
      'currency': currency.code,
    };
  }

  /// Parses stored key/value pairs, falling back to defaults for missing or
  /// unrecognised values so a corrupt row never blocks app startup.
  factory AppSettings.fromMap(Map<String, String?> values) {
    return AppSettings(
      themeMode: AppThemeMode.fromName(values['theme_mode']),
      currency: AppCurrency.fromCode(values['currency']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppSettings &&
            other.themeMode == themeMode &&
            other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(themeMode, currency);

  @override
  String toString() =>
      'AppSettings(themeMode: $themeMode, currency: ${currency.code})';
}
