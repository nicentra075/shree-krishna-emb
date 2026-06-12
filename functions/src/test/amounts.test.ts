import assert from "node:assert/strict";
import { test } from "node:test";

import { computeOrderAmounts } from "../utils/money";

// GOLDEN VALUES — must stay identical to core/test/money_test.dart.
// If a value changes here, the Dart test MUST change with it.

test("₹100 subtotal, 12% fee, 18% GST", () => {
  const amounts = computeOrderAmounts(10000, 12, 18);
  assert.equal(amounts.platformFee, 1200);
  assert.equal(amounts.gstAmount, 2016); // 18% of 11200
  assert.equal(amounts.totalAmount, 13216);
});

test("rounding: ₹9.99 subtotal, 12% fee, 18% GST", () => {
  const amounts = computeOrderAmounts(999, 12, 18);
  assert.equal(amounts.platformFee, 120); // 119.88 → 120
  assert.equal(amounts.gstAmount, 201); // 201.42 → 201
  assert.equal(amounts.totalAmount, 1320);
});

test("zero percentages pass subtotal through", () => {
  const amounts = computeOrderAmounts(14900, 0, 0);
  assert.equal(amounts.platformFee, 0);
  assert.equal(amounts.gstAmount, 0);
  assert.equal(amounts.totalAmount, 14900);
});

test("fractional percentages: ₹500, 2.5% fee, 18% GST", () => {
  const amounts = computeOrderAmounts(50000, 2.5, 18);
  assert.equal(amounts.platformFee, 1250);
  assert.equal(amounts.gstAmount, 9225); // 18% of 51250
  assert.equal(amounts.totalAmount, 60475);
});
