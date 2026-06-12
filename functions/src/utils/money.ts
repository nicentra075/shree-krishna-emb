/**
 * THE fee/GST formula — byte-for-byte mirror of the Dart source of truth:
 *   core/lib/utils/money.dart (Money.computeOrderAmounts)
 *
 * Golden values are asserted identically in core/test/money_test.dart and
 * src/test/amounts.test.ts. If one changes, BOTH must change.
 *
 * All amounts are int paise (INR minor units). Math.round and Dart's
 * .round() agree for all positive values.
 */
export interface OrderAmounts {
  itemsSubtotal: number;
  platformFee: number;
  gstAmount: number;
  totalAmount: number;
}

export function computeOrderAmounts(
  itemsSubtotal: number,
  platformFeePercent: number,
  gstPercent: number,
): OrderAmounts {
  const platformFee = Math.round((itemsSubtotal * platformFeePercent) / 100);
  const gstAmount = Math.round(((itemsSubtotal + platformFee) * gstPercent) / 100);
  return {
    itemsSubtotal,
    platformFee,
    gstAmount,
    totalAmount: itemsSubtotal + platformFee + gstAmount,
  };
}
