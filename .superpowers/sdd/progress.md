# Push Notification Module — SDD Progress Ledger

Plan: docs/superpowers/plans/2026-06-27-push-notification-module.md Branch: development Base before execution: 8040911

## Tasks

Task 1: complete (commits 8040911..654e45e, review clean)
Task 2: complete (commits 654e45e..ff1f6e0, review clean)
Task 2b: complete (covered with Task 2, commit b7bdb2d, review clean)
Task 3: complete (commits b7bdb2d..917c5b4, review clean)
Task 4: complete (commits 917c5b4..6f12df7, review clean)
Task 5: complete (commits 6f12df7..086eadb, review clean)
Task 6: complete (commits 086eadb..196b0b9, review clean)
Task 7: complete (commits 196b0b9..0818283, review clean)
--- PHASE 0 complete ---
Task 8: complete (commits 0818283..234d467, review clean; fcm_messaging ^16.4.1 + flutter_local_notifications ^22.0.1)
Task 9: complete (commits 234d467..fc2c71d, review clean)
Task 10: complete (commits fc2c71d..d10c68d, inline review clean; adapted to flutter_local_notifications v22 named-param API)
--- switched to phase-batched execution for speed (T11+P2 combined, etc.) ---
Task 12: complete (commit d1594c7, batch review)
Task 13: complete (commit 149090e, batch review)
Task 17: complete (commit a2feac9, batch review)
Task 11: complete (commit abebb1b, batch review) + fix 18989a5 (logout uid capture, cubit error surfacing, AuthSuspended cleanup) — re-verified inline, 7/7 cubit tests
NOTE: AuthBloc is a getIt singleton provided via .value at root + per-screen (same instance). MainApp now StatefulWidget caching _lastUid for logout FCM cleanup.
Task 14: complete (commit 830153d, batch review approved)
Task 15: complete (commit ba622a3, batch review approved; added NotificationCubit.markRead)
Task 16: complete (commit 07612e4, batch review approved) + fix 95a33ae (localized relative timestamps)
--- PHASE 1 + PHASE 2 complete (USER APP DONE): FCM plumbing, token lifecycle, inbox datasource/repo/cubit, notification center screen, bell badge + deep-link, localization ---
--- PHASE 3 complete (CLOUD FUNCTIONS): plan T17-23 + index export. commits 1cb596a(messaging+gitignore fix),b989153(digestLogic),d54de0d(broadcast),42d9f10(onOrderFinalized),60292ec(onDesignWritten),c0a1a35(sendNewDesignDigest+cursor-seed),9ee7584(index export). build clean, 12/12 tests. NOT yet reviewed as a batch. ---
NOTE: plan real numbering — T17=functions messaging export (done), T24-31=ADMIN app, T23b=deploy+backfill (backfill SKIPPED per decision#2 cursor-seed), T32=E2E.
REPO BUG (flag to user): functions/.gitignore unanchored `lib/` was ignoring functions/src/lib/*.ts source. Fixed in 1cb596a; 3 pre-existing files now untracked: functions/src/lib/{auth,crypto,razorpay}.ts — imported by committed payments code, so fresh clone/CI is BROKEN today. User must decide to commit them.
--- PHASE 3 REVIEW: Approved. Follow-up: wrap sendNewDesignDigest cursor/firedSlots in db.runTransaction — fixer running now. onDesignWritten 2-invocation self-write = harmless, no fix. ---
--- PHASE 4a (admin settings A2) complete + REVIEW APPROVED (no critical/important; minor dead-string only). T24 62d6a45, T25 ea2c6a4, T26 3745bab, T27 29cf524. ---
--- PHASE 3 digest transaction fix: bfef1d2 (claimSlot db.runTransaction), 12/12 tests. Phase 3 fully done. ---
NOTE: T26 already added broadcast + inbox localization strings (used by Phase 4b). Admin uses getIt<FirebaseFunctions> (region via CloudFunctionNames.region=asia-south1) for callables. admin_notifications doc has readBy[] array (read = readBy.contains(adminId)).
--- PHASE 4b (admin broadcast A3 + inbox A1) complete + REVIEW APPROVED. T28 8bad84a, T29 b20d0f9, T30 58de649, T31 049bba8. analyze clean, 18/18 tests. ---
FOLLOW-UPS (non-blocking, from P4b review): (1) markAllRead uses N sequential writes → could use WriteBatch. (2) admin inbox tap marks-read only, no order/design tap-through. Both disclosed trade-offs, acceptable at current scale.
UNCOMMITTED (flag to user): shree_krishna_emb_user_app/pubspec.yaml+lock have unrelated dep bumps (razorpay_flutter 1.4.0→1.4.5, dio 5.9.2→5.10.0) from a subagent pub run — commit or revert (user decision).
--- ALL 32 TASKS IMPLEMENTED + ALL PHASE REVIEWS PASSED. ---
--- P5 INTEGRATION SWEEP: ALL GREEN (core 18/18, user analyze clean+23/23, admin analyze clean+19/19, functions build+12/12). ---
--- P5 FINAL WHOLE-BRANCH REVIEW (opus): 1 CRITICAL found → fixing. Critical: terminated-launch deep-link lost — consumeInitialMessage() in onLogin pushes designDetail on splash route, then splash navigateToHome pushNamedAndRemoveUntil((route)=>false) wipes it. Fix: defer initial-message routing to home screen first frame. Also fix Minor: firedSlots unbounded (prune non-today keys in claimSlot txn). Timezone-not-honored Minor = documented, India-only, no fix. ---
--- CRITICAL + firedSlots FIXED: 4b3c16a (defer terminated deep-link to MainScreen post-frame), 8d10f49 (prune firedSlots). analyze clean, user 22/22 + functions 12/12. ---
=== MODULE COMPLETE. All 32 tasks + fixes done, all reviews passed. Remaining = USER actions only: deploy (firebase deploy rules/indexes/functions asia-south1), on-device FCM test, iOS APNs setup, decide on untracked functions/src/lib/{auth,crypto,razorpay}.ts, decide on pubspec razorpay/dio drift. Open follow-ups: admin markAllRead WriteBatch, admin inbox tap-through, timezone setting wiring. ===
NOTE: ADMIN app uses OWN Failure/ServerException (package:shree_krishna_emb_admin/core/errors/*), Either from core. Admin auth = AdminAuthBloc/AdminAuthAuthenticated.adminId. service_locator entry = setupAdminServiceLocator. ResponsiveSnackbar.showSuccess/showError(msg, context) static.
NOTE: project Either has NO isRight()/isLeft(); use fold/getOrElse/map/orElse or isA<Right<...>>()/isA<Left<...>>() in tests.