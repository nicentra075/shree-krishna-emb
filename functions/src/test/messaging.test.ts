import assert from "node:assert/strict";
import { test } from "node:test";

import { chunk } from "../notifications/messaging";

test("chunk splits evenly divisible arrays", () => {
  assert.deepEqual(chunk([1, 2, 3, 4], 2), [
    [1, 2],
    [3, 4],
  ]);
});

test("chunk carries the remainder in the last group", () => {
  assert.deepEqual(chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
});

test("chunk with size >= length returns a single group", () => {
  assert.deepEqual(chunk([1, 2], 10), [[1, 2]]);
});

test("chunk of empty array returns empty array", () => {
  assert.deepEqual(chunk([], 3), []);
});
