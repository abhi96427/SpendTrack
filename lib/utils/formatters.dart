import 'package:intl/intl.dart';

import '../models/app_currency.dart';

final Map<AppCurrency, NumberFormat> _currencyFormatters =
    <AppCurrency, NumberFormat>{};

NumberFormat _formatterFor(AppCurrency currency) {
  return _currencyFormatters.putIfAbsent(currency, () {
    return NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: currency.decimalDigits,
    );
  });
}

final DateFormat _shortDateFormatter = DateFormat('d MMM yyyy');
final DateFormat _fullDateFormatter = DateFormat('d MMMM yyyy');
final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy');
final DateFormat _shortMonthFormatter = DateFormat('MMM');
final DateFormat _compactDateFormatter = DateFormat('d MMM');

String formatCurrency(num amount, {AppCurrency currency = AppCurrency.inr}) =>
    _formatterFor(currency).format(amount);

/// Compact currency used inside charts and small labels.
///
/// INR keeps its familiar crore/lakh/thousand suffixes. Other currencies use
/// the locale-aware compact notation so foreign amounts remain readable.
String formatCompactCurrency(
  num amount, {
  AppCurrency currency = AppCurrency.inr,
}) {
  final value = amount.toDouble();
  if (value <= 0) {
    return '${currency.symbol}0';
  }

  if (currency == AppCurrency.inr) {
    if (value >= 10000000) {
      return '${currency.symbol}${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (value >= 100000) {
      return '${currency.symbol}${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      final thousands = value / 1000;
      final digits = thousands >= 10 ? 0 : 1;
      return '${currency.symbol}${thousands.toStringAsFixed(digits)}k';
    }
    if (value < 10) {
      return '${currency.symbol}${value.toStringAsFixed(2)}';
    }
    if (value < 100) {
      return '${currency.symbol}${value.toStringAsFixed(1)}';
    }
    return '${currency.symbol}${value.toStringAsFixed(0)}';
  }

  final digits = value < 10 ? 2 : (value < 100 ? 1 : 0);
  return NumberFormat.compactCurrency(
    locale: currency.locale,
    symbol: currency.symbol,
    decimalDigits: digits,
  ).format(value);
}

String formatShortDate(DateTime date) =>
    _shortDateFormatter.format(date.toLocal());

String formatFullDate(DateTime date) =>
    _fullDateFormatter.format(date.toLocal());

String formatMonthYear(DateTime date) =>
    _monthYearFormatter.format(date.toLocal());

String formatShortMonth(DateTime date) =>
    _shortMonthFormatter.format(date.toLocal());

String formatCompactDate(DateTime date) =>
    _compactDateFormatter.format(date.toLocal());

/// Formats an amount for pre-filling the edit form without unnecessary zeros.
String formatAmountInput(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toStringAsFixed(0);
  }
  return amount.toStringAsFixed(2);
}

/// Shows recent days as words and falls back to a short date.
String formatRelativeDate(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(local.year, local.month, local.day);
  final difference = today.difference(target).inDays;

  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  return _shortDateFormatter.format(local);
}
