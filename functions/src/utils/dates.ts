/**
 * Date helpers. Convention (docs/integration/FIRESTORE_SCHEMA.md §1):
 * all model dates are ISO-8601 UTC strings; TTL fields are Timestamps.
 */

/** ISO-8601 UTC string, e.g. "2026-06-12T09:30:00.000Z". */
export function nowIso(): string {
  return new Date().toISOString();
}

/**
 * statsDaily doc key for "today" in Indian business time (Asia/Kolkata),
 * formatted yyyy-MM-dd.
 */
export function todayKey(date: Date = new Date()): string {
  // en-CA locale formats as yyyy-MM-dd.
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Kolkata",
  }).format(date);
}
