import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

void main() {
  group('Money.computeOrderAmounts — GOLDEN VALUES', () {
    // These exact values are mirrored in functions/test/amounts.test.ts.
    // If a value changes here, the functions test MUST change with it.
    test('₹100 subtotal, 12% fee, 18% GST', () {
      final amounts = Money.computeOrderAmounts(
        itemsSubtotal: 10000,
        platformFeePercent: 12,
        gstPercent: 18,
      );
      expect(amounts.platformFee, 1200);
      expect(amounts.gstAmount, 2016); // 18% of 11200
      expect(amounts.totalAmount, 13216);
    });

    test('rounding: ₹9.99 subtotal, 12% fee, 18% GST', () {
      final amounts = Money.computeOrderAmounts(
        itemsSubtotal: 999,
        platformFeePercent: 12,
        gstPercent: 18,
      );
      expect(amounts.platformFee, 120); // 119.88 → 120
      expect(amounts.gstAmount, 201); // 18% of 1119 = 201.42 → 201
      expect(amounts.totalAmount, 1320);
    });

    test('zero percentages pass subtotal through', () {
      final amounts = Money.computeOrderAmounts(
        itemsSubtotal: 14900,
        platformFeePercent: 0,
        gstPercent: 0,
      );
      expect(amounts.platformFee, 0);
      expect(amounts.gstAmount, 0);
      expect(amounts.totalAmount, 14900);
    });

    test('fractional percentages: ₹500, 2.5% fee, 18% GST', () {
      final amounts = Money.computeOrderAmounts(
        itemsSubtotal: 50000,
        platformFeePercent: 2.5,
        gstPercent: 18,
      );
      expect(amounts.platformFee, 1250);
      expect(amounts.gstAmount, 9225); // 18% of 51250
      expect(amounts.totalAmount, 60475);
    });
  });

  group('Money.formatPaise', () {
    test('formats with Indian lakh grouping', () {
      expect(Money.formatPaise(149000), '₹1,490.00');
      expect(Money.formatPaise(12345678), '₹1,23,456.78');
    });

    test('formats zero and sub-rupee values', () {
      expect(Money.formatPaise(0), '₹0.00');
      expect(Money.formatPaise(50), '₹0.50');
    });
  });

  group('KeywordBuilder.build', () {
    test('tokenizes, lowercases, dedupes, and includes all sources', () {
      final keywords = KeywordBuilder.build(
        title: 'Royal Peacock Bridal Blouse',
        categoryName: 'Bridal Blouses',
        techniques: ['Zardosi', 'Mirror Work'],
        threadType: 'Silk',
      );
      expect(
        keywords,
        containsAll([
          'royal',
          'peacock',
          'bridal',
          'blouse',
          'blouses',
          'zardosi',
          'mirror',
          'work',
          'silk',
        ]),
      );
      // 'bridal' appears in title AND category — deduped.
      expect(keywords.where((k) => k == 'bridal').length, 1);
    });

    test('drops single-character tokens and caps at 30', () {
      final keywords = KeywordBuilder.build(
        title: List.generate(40, (i) => 'word$i').join(' x '),
      );
      expect(keywords.length, KeywordBuilder.maxKeywords);
      expect(keywords.contains('x'), isFalse);
    });

    test('preserves Devanagari tokens for Hindi titles', () {
      final keywords = KeywordBuilder.build(title: 'दुल्हन ब्लाउज Design');
      expect(keywords, containsAll(['दुल्हन', 'ब्लाउज', 'design']));
    });
  });
}
