import 'package:flutter_test/flutter_test.dart';
import 'package:spendtrack/utils/formatters.dart';

void main() {
  group('formatCompactCurrency', () {
    test('keeps precision for amounts below one thousand', () {
      expect(formatCompactCurrency(0), '₹0');
      expect(formatCompactCurrency(0.5), '₹0.50');
      expect(formatCompactCurrency(5.5), '₹5.50');
      expect(formatCompactCurrency(42.75), '₹42.8');
      expect(formatCompactCurrency(999), '₹999');
    });

    test('uses Indian compact units for large amounts', () {
      expect(formatCompactCurrency(1200), '₹1.2k');
      expect(formatCompactCurrency(15000), '₹15k');
      expect(formatCompactCurrency(150000), '₹1.5L');
      expect(formatCompactCurrency(15000000), '₹1.5Cr');
    });
  });
}
