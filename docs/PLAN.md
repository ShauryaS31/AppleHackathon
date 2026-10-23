# Plan and Task Board

Event: AI On Apple, Sydney. 20 Martin Place, Level 3. All times AEDT (UTC+11).
Manager updates the Status column. Each task's full brief is in `tasks/`.

## Milestones and gates

| Milestone | Date and time | Tasks | Gate (owner checks on device) |
|---|---|---|---|
| M0 Setup | Fri 23 Oct, 13:00 to 21:00 | T00, T01 | CI green; app runs on iPhone and reports Apple Intelligence available |
| M1 Core pipeline | Sat 24 Oct, 10:00 to 12:30 | T02 to T06 (incl. T04b, T05a, T05b) | Benchmark run on device; numbers in LOG; SCX debug call returns |
| M2 Screens and input | Sat 24 Oct, 12:30 to 15:30 | T07 to T09 | Share a WhatsApp message as text (or paste it) in airplane mode, item appears in Review with evidence |
| M3 Act | Sat 24 Oct, 15:30 to 18:00 | T10, T11 | Approve item, real event in Apple Calendar, notification fires |
| M4 Sovereign planning | Sat 24 Oct, 18:00 to 20:00 | T12, T13 | Ledger shows placeholders only and region AU; names restored in answer |
| M5 Voice and Siri | Sun 25 Oct, 10:00 to 12:00 | T14, T15 | Briefing audible; Siri answers "what did I promise Adit" |
| M6 Demo hardening | Sun 25 Oct, 12:00 to 13:00 | T16 | Two clean 5-minute runs. **Code freeze 13:00** |
| Pitch | Sun 25 Oct, 13:00 to 14:00 | owner | Rehearse; judging 14:00 |
| Stretch | When ahead of plan | T17, T18 | Only after M3 passes |

Parallel lanes on Saturday morning: T06 (SCX spike) runs in its own worktree alongside T02 to T05a. T03 and T04 can run in parallel after T02.

## Task board

| Task | Title | Milestone | Window | Depends on | Assignee | Status |
|---|---|---|---|---|---|---|
| [T00](../tasks/T00-factory-check.md) | Factory smoke test and accounts | M0 | Fri 23 Oct, 13:00 to 18:00 | - | owner + manager | blocked |
| [T01](../tasks/T01-scaffold.md) | Repo scaffold: XcodeGen project, Core package, Share extension, CI | M0 | Fri 23 Oct, 18:30 to 21:00 | T00 | codex | done |
| [T02](../tasks/T02-core-models.md) | Core models, protocols and fakes | M1 | Sat 24 Oct, 10:00 to 10:45 | T01 | codex | done |
| [T03](../tasks/T03-prefilter.md) | Normaliser, quote and signature stripper, rules prefilter | M1 | Sat 24 Oct, 10:45 to 11:30 | T02 | codex | done |
| [T04](../tasks/T04-resolvers.md) | DateResolver, EvidenceValidator, Matcher, ConflictDetector | M1 | Sat 24 Oct, 10:45 to 12:00 | T02 | codex | done |
| [T04b](../tasks/T04b-date-phrases.md) | DateResolver: common date phrasings | M1 | Fri 23 Oct (Windows mode) | T04 | codex | done |
| [T04c](../tasks/T04c-timezone-suffixes.md) | DateResolver: timezone suffixes | M1 | Fri 23 Oct (Windows mode) | T04b, T09 | codex | todo |
| [T05a](../tasks/T05a-instructions-benchmark.md) | Extraction instructions and benchmark fixtures | M1 | Fri 23 Oct (Windows mode) | T03, T04b | codex | done |
| [T05b](../tasks/T05b-fm-extractor.md) | Foundation Models extractor and on-device benchmark screen | M1 | When the Mac arrives | T05a, T09 | codex, then owner on device | blocked |
| [T06](../tasks/T06-scx-spike.md) | SCXSwiftKit spike: PlanningModel implementation | M1 | Sat 24 Oct, 10:00 to 11:30 (parallel worktree) | T01 | codex | todo |
| [T07](../tasks/T07-store-today.md) | SwiftData store, seed dataset, Today agenda, item detail | M2 | Sat 24 Oct, 12:30 to 14:00 | T05a | codex | done |
| [T07b](../tasks/T07b-no-date-section.md) | "No date" section on Today | M2 | Fri 23 Oct (Windows mode) | T07, T08 | codex | todo |
| [T08](../tasks/T08-review.md) | Review queue | M2 | Sat 24 Oct, 13:30 to 14:30 | T07 | codex | done |
| [T09](../tasks/T09-share-paste.md) | Share extension and paste input (text only) | M2 | Sat 24 Oct, 14:00 to 15:30 | T07 | codex, then owner on device | done |
| [T10](../tasks/T10-eventkit.md) | EventKit conflicts, approved event creation, receipts | M3 | Sat 24 Oct, 15:30 to 17:00 | T08 | codex | todo |
| [T11](../tasks/T11-notifications.md) | Local notification reminders | M3 | Sat 24 Oct, 16:30 to 18:00 | T10 | codex | todo |
| [T12](../tasks/T12-pseudonymiser.md) | Pseudonymiser and 'What left my phone' ledger | M4 | Sat 24 Oct, 18:00 to 19:00 | T02 | codex | done |
| [T13](../tasks/T13-plan-week.md) | Plan my week via SCX MAGPiE | M4 | Sat 24 Oct, 19:00 to 20:00 | T06, T12 | codex | todo |
| [T14](../tasks/T14-voice.md) | ElevenLabs morning briefing | M5 | Sun 25 Oct, 10:00 to 11:00 | T07 | codex, then owner on device | todo |
| [T15](../tasks/T15-app-intents.md) | App Intents for Siri and Shortcuts | M5 | Sun 25 Oct, 10:30 to 12:00 | T07 | codex | todo |
| [T16](../tasks/T16-demo-hardening.md) | Demo hardening | M6 | Sun 25 Oct, 12:00 to 13:00 (code freeze 13:00) | T09, T11, T13, T14 | codex + owner | todo |
| [T17](../tasks/T17-gmail.md) | STRETCH: Gmail fetch from device | Stretch | Only if M3 passes by 17:00 Sat | T10 | codex | todo |
| [T18](../tasks/T18-coreml-triage.md) | STRETCH: Create ML triage classifier | Stretch | Only if ahead of plan | T05b | owner + codex | todo |

## Mac gate checklist
Runtime checks the agents cannot do on Windows. Each review marks them "PENDING DEVICE"; run them all when the Mac (and iPhone) are available. Tick here and record evidence in LOG.

| From | Check | Done |
|---|---|---|
| T00 | `xcodebuild -version` shows Xcode 26; device has Apple Intelligence; signing works | [ ] |
| T01 | Recalled launches on iPhone and RecalledMac on the Mac; placeholder shows on-device model availability | [ ] |
| T12 | Pseudonymiser on device: names and organisations in the demo data are all replaced (NLTagger quality) | [ ] |
| T07 | Store files carry NSFileProtectionComplete; data survives relaunch; launch while locked recovers when unlocked | [ ] |
| T07 | Reset demo twice: 15 items, no duplicates, dates relative to today; tentative and conflict badges render (Sprint check-in conflict) | [ ] |
| T07 | Detail highlights the excerpt in its bounded context; menu reaches Settings and Ledger | [ ] |
| T07 | Forget all, then relaunch: everything empty; unprovisioned RecalledMac falls back to the default store and logs once | [ ] |
| T08 | Review tab badge count matches the queue; each action (Confirm, Edit, Dismiss, Mark as same, Create) removes the row and updates Today without relaunch | [ ] |
| T08 | Edit date picker, date-only toggle and No date option work on iPhone and Mac | [ ] |
| T09 | Share WhatsApp text in airplane mode: item lands in Review with the extractor-not-wired reason and a bounded excerpt (A1, A10); repeat after T05b with the real model | [ ] |
| T09 | Share from Messages, Slack and Mail is accepted; one Safari URL accepted; two URLs or an image do not activate the extension | [ ] |
| T09 | Paste message on iPhone and RecalledMac (also with an empty clipboard); data-protection entitlement signs on device | [ ] |
| T09 | Kill the app mid-import, relaunch: file kept and imported once; Forget all removes pending Inbox files | [ ] |

## Owner-only work (not for agents)
- Fri: hardware and accounts (T00), confirm prior-work rule with organisers, find team (iOS dev or designer).
- Sat 20:00: draft pitch slides and demo script from SPEC section 5.
- Sun 12:30: record fallback demo video.
- Sun 13:00: rehearse twice with a stopwatch.

## Decisions log
| Date | Decision | By |
|---|---|---|
| 2026-10-23 | Build Recalled as native iOS 26 app; on-device extraction with Foundation Models; SCX MAGPiE for planning only | Shaurya |
| 2026-10-23 | Claude Code manages and reviews; Codex gpt-6-astra develops; one fresh codex exec per task round | Shaurya |
| 2026-10-23 | XcodeGen project.yml instead of committed .pbxproj, so agents edit YAML not project files | Manager |
| 2026-10-23 | Zero budget and stay native Swift. Repo made public (history checked for secrets first) so GitHub Actions macOS runners are free | Shaurya |
| 2026-10-23 | Windows mode: run T01, T02, T03, T04, T12 in that order now, each gated by a green GitHub Actions `core-tests` run on the task branch (no local Swift on Windows). Stop after T12. T01 also adds an `app-build` CI job (xcodegen + xcodebuild, unsigned) so app code gets compile checked; required for tasks that touch app code (T01, T12) | Shaurya, Manager |
| 2026-10-23 | T01 adds a native macOS 26 target `RecalledMac` (same app sources, no share extension) as the fallback demo device on an Apple silicon Mac | Shaurya |
| 2026-10-23 | Drop OCR. T09 becomes "Share extension and paste input (text only)": shared text and URLs plus an in-app "Paste message" button. SPEC 5 step 2, 6 M1, 7 diagram, 7.1, 7.7, A1 and the M2 gate updated | Shaurya |
| 2026-10-23 | T04 date gaps promoted to required task T04b ("by Friday", "Sat 25 Oct", "25 Oct", "Friday 3pm", "tonight", "next week Tue", "end of month"); unknown phrasing still goes to Review. Gate: core-tests | Shaurya |
| 2026-10-23 | T05 split: T05a instructions port plus 20 benchmark fixtures (gate app-build); T05b Foundation Models wiring and on-device benchmark, blocked until the device is available | Shaurya |
| 2026-10-23 | Windows mode continues: T09 doc change, T04b, T05a, T07, T08, T09, T10. App tasks gated by app-build CI; runtime criteria marked PENDING DEVICE in reviews and collected in "Mac gate checklist". Stop after T10 or when the owner says the Mac has arrived | Shaurya |
| 2026-10-23 | Inbox pipeline (prefilter, extractor, evidence, dates, matcher) lives in RecalledCore and is tested with FakeExtractor in T09, so it is covered by core-tests before Foundation Models is wired in T05b | Manager |
| 2026-10-23 | T09 round 2 restart: save the partial diff as a patch, discard, redispatch clean. Superseded on inspection: the round had not been interrupted (only the dispatch wrapper was stopped; codex.exe finished and committed f9ea364), so the manager reviews f9ea364 as round 2 | Shaurya, Manager |
| 2026-10-23 | New required task T04c: DateResolver timezone suffixes ("10:00 AM Australia/Sydney", "17:00 Sydney time", "6pm AEDT", "9am UTC", "3pm Perth time"), converted to the user's zone with the source zone kept on the record; re-run the 15 ported fixtures. Gate: core-tests | Shaurya |
| 2026-10-23 | New required task T07b: "No date" section on Today for confirmed items without a date. Gate: app-build | Shaurya |
| 2026-10-23 | Order: T09 round 2, T04c, T07b, T10. Stop after T10 or when the owner says the Mac has arrived | Shaurya |
| 2026-10-23 | Process: one codex process at a time unless using worktrees; after each round confirm no `codex exec` process is left and stop leftovers; an interrupted round is saved as a patch and discarded before redispatch (CLAUDE.md) | Shaurya |
