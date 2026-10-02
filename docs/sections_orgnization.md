# Sections organization — progress snapshot

Updated 2026-10-02 after merging section 6 and the Today checkpoint into main, counted from the **Progress**
checkboxes in `docs/tasks_section_*.md`.

**Total: 610 done / 132 missing / 742 tasks (≈82 %)**

| Section | Done | Missing |
|---|---|---|
| **1 Foundation** | **84** | **5** |
| 1.1 Repo tooling | 16 | 1 |
| 1.2 Backend setup | 13 | 4 |
| 1.3 App shell | 19 | 0 ✅ |
| 1.4 Local DB / sync | 19 | 0 ✅ |
| 1.5 Auth / profile | 17 | 0 ✅ |
| **2 Core engines** | **46** | **0 ✅** |
| 2.1 Recurrence engine | 20 | 0 ✅ |
| 2.2 Attachments | 14 | 0 ✅ |
| 2.3 Shared primitives | 12 | 0 ✅ |
| **3 Plan** | **136** | **0 ✅** |
| 3.1 Task model / editor | 21 | 0 ✅ |
| 3.2 Recurring series | 23 | 0 ✅ |
| 3.3 Time grid engine | 26 | 0 ✅ |
| 3.4 Week table | 20 | 0 ✅ |
| 3.5 Day list | 15 | 0 ✅ |
| 3.6 Calendar views | 17 | 0 ✅ |
| 3.7 Focus / productivity views | 14 | 0 ✅ |
| **4 Lists** | **74** | **0 ✅** |
| 4.1 Checklist model / board | 17 | 0 ✅ |
| 4.2 Nested tree editor | 19 | 0 ✅ |
| 4.3 Item status workflow | 12 | 0 ✅ |
| 4.4 Item attachments | 9 | 0 ✅ |
| 4.5 Advanced views | 17 | 0 ✅ |
| **5 Habits** | **58** | **0 ✅** |
| **6 Insights** | **142** | **1** |
| 6.1 Stats engine | 26 | 1 (T6.1.27 rollups: waits for device profiling) |
| 6.2 Chart components | 26 | 0 ✅ |
| 6.3 Planner stats | 21 | 0 ✅ |
| 6.4 Checklist stats | 18 | 0 ✅ |
| 6.5 Habit stats | 18 | 0 ✅ |
| 6.6 Quit stats | 14 | 0 ✅ |
| 6.7 Dashboard / reports | 19 | 0 ✅ |
| **7 Notifications** | **60** | **34** |
| 7.1 Rules | 15 | 3 |
| 7.2 Local notifications | 21 | 5 |
| 7.3 In-app inbox | 10 | 1 |
| 7.4 Push / FCM server | 6 | 13 |
| 7.5 Section catalog | 8 | 12 |
| **8 Cross-cutting** | **10** | **40** |
| 8.1 Today / search / quick add | 2 | 16 |
| 8.2 Widgets / integrations | 1 | 14 |
| 8.3 Settings / data / privacy | 7 | 10 |
| **9 Quality & release** | **0** | **52 ❌** |
| 9.1 Testing / quality | 0 | 16 |
| 9.2 Release / operations | 0 | 18 |
| 9.3 Post-launch roadmap | 0 | 18 |

## Summary

- Done: Core engines (2), Plan (3), Lists (4), Habits (5) and Insights (6, except the T6.1.27 rollups
  decision) complete; sync and recurrence done.
- Biggest gaps: push + notification catalog (7.4–7.5),
  all of 8 and 9.
- Not started: 9.1, 9.2, 9.3.

## Section 1 — what is left (needs the owner's accounts / tools, steps in `docs/guide.md`)

- T1.1.05 iOS build: needs Xcode ≥ 26 (this Mac has 16.4).
- T1.2.02 Supabase cloud projects + keys (§4 of the guide).
- T1.2.13 Firebase projects per flavor — run the two `flutterfire configure` commands (§5).
- T1.2.14 APNs key upload + test push on a device (§6); entitlements already in the app.
- T1.2.15 Crashlytics native plugins (added by `flutterfire configure`) + a test crash (§5 step 7).
