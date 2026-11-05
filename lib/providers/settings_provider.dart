import 'package:flutter/foundation.dart';

import '../models/app_currency.dart';
import '../models/app_settings.dart';
import '../services/expense_repository.dart';
import '../services/settings_repository.dart';

/// Owns the persisted user preferences and exposes them to the widget tree.
///
/// Changes are applied optimistically and rolled back if persistence fails, so
/// the settings screen never claims a preference was saved when it was not.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required SettingsRepository repository,
    AppSettings initial = AppSettings.defaults,
  }) : _repository = repository,
       _settings = initial;

  final SettingsRepository _repository;

  AppSettings _settings;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AppSettings get settings => _settings;
  AppThemeMode get themeMode => _settings.themeMode;
  AppCurrency get currency => _settings.currency;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Loads persisted settings. Safe to call again to retry.
  Future<void> initialize() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.loadSettings();
      _isInitialized = true;
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setThemeMode(AppThemeMode mode) {
    if (mode == _settings.themeMode) {
      return Future<bool>.value(true);
    }
    return _update(_settings.copyWith(themeMode: mode));
  }

  Future<bool> setCurrency(AppCurrency currency) {
    if (currency == _settings.currency) {
      return Future<bool>.value(true);
    }
    return _update(_settings.copyWith(currency: currency));
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _update(AppSettings next) async {
    final previous = _settings;

    _settings = next;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveSettings(next);
      return true;
    } catch (error) {
      _settings = previous;
      _errorMessage = _messageFor(error);
      notifyListeners();
      return false;
    }
  }

  String _messageFor(Object error) {
    if (error is StorageException) {
      return error.message;
    }
    return 'Unable to update your preferences. Please try again.';
  }
}
