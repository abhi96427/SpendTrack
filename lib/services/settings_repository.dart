import '../models/app_settings.dart';

/// Abstraction over persisted app preferences.
///
/// Kept separate from [ExpenseRepository] so settings can be tested and
/// replaced independently from expense storage.
abstract interface class SettingsRepository {
  /// Reads the saved settings, returning [AppSettings.defaults] when nothing
  /// has been stored yet.
  Future<AppSettings> loadSettings();

  /// Persists the complete settings snapshot.
  Future<void> saveSettings(AppSettings settings);
}

/// A lightweight non-persistent [SettingsRepository].
///
/// Production uses the SQLite implementation. This fallback keeps widget
/// previews and tests functional when no settings store is supplied.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({AppSettings initial = AppSettings.defaults})
    : _settings = initial;

  AppSettings _settings;

  @override
  Future<AppSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}
