import assert from "node:assert/strict";
import { test } from "node:test";

import { dayKey, hhmm, selectDueSlot } from "../notifications/digestLogic";

test("selectDueSlot returns the latest due slot not yet fired", () => {
  assert.equal(
    selectDueSlot({ slots: ["10:00", "14:00", "18:00"], firedToday: ["10:00"], nowHHmm: "14:30" }),
    "14:00",
  );
});

test("selectDueSlot returns null before the first slot", () => {
  assert.equal(selectDueSlot({ slots: ["10:00"], firedToday: [], nowHHmm: "09:00" }), null);
});

test("selectDueSlot returns null when all due slots already fired", () => {
  assert.equal(
    selectDueSlot({ slots: ["10:00", "14:00"], firedToday: ["10:00", "14:00"], nowHHmm: "23:00" }),
    null,
  );
});

test("dayKey/hhmm shift by the IST offset (+330 minutes)", () => {
  // 2026-01-01T20:00:00Z + 330min = 2026-01-02T01:30 IST
  const d = new Date("2026-01-01T20:00:00Z");
  assert.equal(dayKey(d, 330), "2026-01-02");
  assert.equal(hhmm(d, 330), "01:30");
});
