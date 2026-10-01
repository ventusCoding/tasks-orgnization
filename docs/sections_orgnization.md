# Sections organization — progress snapshot

Updated 2026-10-01 after section 2 work (branch `section-2-completion`), counted from the **Progress**
checkboxes in `docs/tasks_section_*.md`.

**Total: 514 done / 228 missing / 742 tasks (≈69 %)**

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
| **3 Plan** | **110** | **26** |
| 3.1 Task model / editor | 20 | 1 |
| 3.2 Recurring series | 23 | 0 ✅ |
| 3.3 Time grid engine | 25 | 1 |
| 3.4 Week table | 19 | 1 |
| 3.5 Day list | 15 | 0 ✅ |
| 3.6 Calendar views | 8 | 9 |
| 3.7 Focus / productivity views | 0 | 14 ❌ |
| **4 Lists** | **70** | **4** |
| 4.1 Checklist model / board | 16 | 1 |
| 4.2 Nested tree editor | 19 | 0 ✅ |
| 4.3 Item status workflow | 12 | 0 ✅ |
| 4.4 Item attachments | 8 | 1 |
| 4.5 Advanced views | 15 | 2 |
| **5 Habits** | **58** | **0 ✅** |
| **6 Insights** | **77** | **66** |
| 6.1 Stats engine | 24 | 3 |
| 6.2 Chart components | 12 | 14 |
| 6.3 Planner stats | 10 | 11 |
| 6.4 Checklist stats | 8 | 10 |
| 6.5 Habit stats | 10 | 8 |
| 6.6 Quit stats | 9 | 5 |
| 6.7 Dashboard / reports | 4 | 15 |
| **7 Notifications** | **60** | **34** |
| 7.1 Rules | 15 | 3 |
| 7.2 Local notifications | 21 | 5 |
| 7.3 In-app inbox | 10 | 1 |
| 7.4 Push / FCM server | 6 | 13 |
| 7.5 Section catalog | 8 | 12 |
| **8 Cross-cutting** | **9** | **41** |
| 8.1 Today / search / quick add | 1 | 17 |
| 8.2 Widgets / integrations | 1 | 14 |
| 8.3 Settings / data / privacy | 7 | 10 |
| **9 Quality & release** | **0** | **52 ❌** |
| 9.1 Testing / quality | 0 | 16 |
| 9.2 Release / operations | 0 | 18 |
| 9.3 Post-launch roadmap | 0 | 18 |

## Summary

- Done: Core engines (2) and Habits (5) complete; Lists (4) nearly; Plan (3) nearly except Focus + Calendar views; sync and
  recurrence done.
- Biggest gaps: Insights charts / stats / dashboard (6.2–6.7), push + notification catalog (7.4–7.5),
  all of 8 and 9.
- Not started: 3.7, 9.1, 9.2, 9.3.

## Section 1 — what is left (needs the owner's accounts / tools, steps in `docs/guide.md`)

- T1.1.05 iOS build: needs Xcode ≥ 26 (this Mac has 16.4).
- T1.2.02 Supabase cloud projects + keys (§4 of the guide).
- T1.2.13 Firebase projects per flavor — run the two `flutterfire configure` commands (§5).
- T1.2.14 APNs key upload + test push on a device (§6); entitlements already in the app.
- T1.2.15 Crashlytics native plugins (added by `flutterfire configure`) + a test crash (§5 step 7).
