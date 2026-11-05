/// Returns the trimmed title, or an error message for the form.
String? validateExpenseTitle(String? value) {
  final title = value?.trim() ?? '';
  if (title.isEmpty) {
    return 'Enter a title.';
  }
  if (title.length > 80) {
    return 'Keep the title under 80 characters.';
  }
  return null;
}

/// Validates a positive amount entered as text.
String? validateExpenseAmount(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Enter an amount.';
  }

  final amount = parseAmount(text);
  if (amount == null || !amount.isFinite) {
    return 'Enter a valid number.';
  }
  if (amount <= 0) {
    return 'Amount must be greater than zero.';
  }
  if (amount > 1000000000) {
    return 'Amount is too large.';
  }
  return null;
}

/// Parses user-entered amounts, tolerating thousands separators.
///
/// Non-finite values such as `NaN` or `Infinity` are rejected because they
/// would poison every total and chart derived from the saved records.
double? parseAmount(String value) {
  final normalized = value.replaceAll(',', '').trim();
  if (normalized.isEmpty) {
    return null;
  }
  final amount = double.tryParse(normalized);
  return amount != null && amount.isFinite ? amount : null;
}
