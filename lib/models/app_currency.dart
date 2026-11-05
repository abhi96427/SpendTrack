/// Currencies SpendTrack can display amounts in.
///
/// The enum name is never persisted directly; [code] is stored instead so
/// renaming a value would not invalidate saved settings.
enum AppCurrency {
  inr(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
    locale: 'en_IN',
    decimalDigits: 2,
  ),
  usd(
    code: 'USD',
    name: 'US Dollar',
    symbol: r'$',
    locale: 'en_US',
    decimalDigits: 2,
  ),
  eur(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    locale: 'de_DE',
    decimalDigits: 2,
  ),
  gbp(
    code: 'GBP',
    name: 'British Pound',
    symbol: '£',
    locale: 'en_GB',
    decimalDigits: 2,
  ),
  aed(
    code: 'AED',
    name: 'UAE Dirham',
    symbol: 'AED',
    locale: 'en_AE',
    decimalDigits: 2,
  ),
  aud(
    code: 'AUD',
    name: 'Australian Dollar',
    symbol: r'A$',
    locale: 'en_AU',
    decimalDigits: 2,
  ),
  cad(
    code: 'CAD',
    name: 'Canadian Dollar',
    symbol: r'C$',
    locale: 'en_CA',
    decimalDigits: 2,
  ),
  sgd(
    code: 'SGD',
    name: 'Singapore Dollar',
    symbol: r'S$',
    locale: 'en_SG',
    decimalDigits: 2,
  ),
  jpy(
    code: 'JPY',
    name: 'Japanese Yen',
    symbol: '¥',
    locale: 'ja_JP',
    decimalDigits: 0,
  );

  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.locale,
    required this.decimalDigits,
  });

  /// ISO 4217 code persisted in local settings.
  final String code;

  /// Human readable name shown in the settings screen.
  final String name;

  /// Symbol used by the currency formatter and amount input.
  final String symbol;

  /// Locale used for digit grouping and decimal separators.
  final String locale;

  /// Number of fractional digits shown for whole amounts.
  final int decimalDigits;

  /// `INR · Indian Rupee`, used in selection controls.
  String get label => '$code · $name';

  /// Falls back to the default currency when a stored value is unknown.
  static AppCurrency fromCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    for (final currency in values) {
      if (currency.code == normalized) {
        return currency;
      }
    }
    return AppCurrency.inr;
  }
}
