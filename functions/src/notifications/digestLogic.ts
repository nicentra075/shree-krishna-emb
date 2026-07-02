/**
 * Pure digest slot/cursor selection logic — no Firestore/IO.
 *
 * Used by sendNewDesignDigest (T23) to decide whether a digest is due for
 * the current 30-minute scheduler tick, and to compute day/time keys in a
 * fixed IST offset (India has no DST, so a fixed offset is correct).
 */

export interface SlotInput {
  slots: string[]; // ["HH:mm"]
  firedToday: string[]; // ["HH:mm"] already sent today
  nowHHmm: string; // "HH:mm" in target tz
}

/** Latest slot whose time <= now and not already fired today. */
export function selectDueSlot(i: SlotInput): string | null {
  const due = i.slots
    .filter((s) => s <= i.nowHHmm && !i.firedToday.includes(s))
    .sort(); // lexical sort works for zero-padded HH:mm
  return due.length ? due[due.length - 1] : null;
}

/** Shift a UTC date by tz offset minutes. */
function shifted(d: Date, tzOffsetMinutes: number): Date {
  return new Date(d.getTime() + tzOffsetMinutes * 60_000);
}

/** YYYY-MM-DD in the given tz offset. */
export function dayKey(d: Date, tzOffsetMinutes: number): string {
  const x = shifted(d, tzOffsetMinutes);
  return x.toISOString().slice(0, 10);
}

/** HH:mm in the given tz offset. */
export function hhmm(d: Date, tzOffsetMinutes: number): string {
  const x = shifted(d, tzOffsetMinutes);
  return x.toISOString().slice(11, 16);
}
