import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/app_currency.dart';
import '../providers/settings_provider.dart';

/// Currency accessors for widgets and event handlers.
extension CurrencyContext on BuildContext {
  /// Rebuilds the calling widget when the selected currency changes.
  AppCurrency get currency =>
      Provider.of<SettingsProvider?>(this)?.currency ?? AppCurrency.inr;

  /// Reads the currency without creating a dependency. Use inside callbacks.
  AppCurrency get readCurrency =>
      Provider.of<SettingsProvider?>(this, listen: false)?.currency ??
      AppCurrency.inr;
}
