# Plan and Task Board

Event: AI On Apple, Sydney. 20 Martin Place, Level 3. All times AEDT (UTC+11).
Manager updates the Status column. Each task's full brief is in `tasks/`.

## Milestones and gates

| Milestone | Date and time | Tasks | Gate (owner checks on device) |
|---|---|---|---|
| M0 Setup | Fri 23 Oct, 13:00 to 21:00 | T00, T01 | CI green; app runs on iPhone and reports Apple Intelligence available |
| M1 Core pipeline | Sat 24 Oct, 10:00 to 12:30 | T02 to T06 | Benchmark run on device; numbers in LOG; SCX debug call returns |
| M2 Screens and input | Sat 24 Oct, 12:30 to 15:30 | T07 to T09 | Share a WhatsApp screenshot in airplane mode, item appears in Review with evidence |
| M3 Act | Sat 24 Oct, 15:30 to 18:00 | T10, T11 | Approve item, real event in Apple Calendar, notification fires |
| M4 Sovereign planning | Sat 24 Oct, 18:00 to 20:00 | T12, T13 | Ledger shows placeholders only and region AU; names restored in answer |
| M5 Voice and Siri | Sun 25 Oct, 10:00 to 12:00 | T14, T15 | Briefing audible; Siri answers "what did I promise Adit" |
| M6 Demo hardening | Sun 25 Oct, 12:00 to 13:00 | T16 | Two clean 5-minute runs. **Code freeze 13:00** |
| Pitch | Sun 25 Oct, 13:00 to 14:00 | owner | Rehearse; judging 14:00 |
| Stretch | When ahead of plan | T17, T18 | Only after M3 passes |

Parallel lanes on Saturday morning: T06 (SCX spike) runs in its own worktree alongside T02 to T05. T03 and T04 can run in parallel after T02.

## Task board

| Task | Title | Milestone | Window | Depends on | Assignee | Status |
|---|---|---|---|---|---|---|
| [T00](../tasks/T00-factory-check.md) | Factory smoke test and accounts | M0 | Fri 23 Oct, 13:00 to 18:00 | - | owner + manager | in_progress |
| [T01](../tasks/T01-scaffold.md) | Repo scaffold: XcodeGen project, Core package, Share extension, CI | M0 | Fri 23 Oct, 18:30 to 21:00 | T00 | codex | todo |
| [T02](../tasks/T02-core-models.md) | Core models, protocols and fakes | M1 | Sat 24 Oct, 10:00 to 10:45 | T01 | codex | todo |
| [T03](../tasks/T03-prefilter.md) | Normaliser, quote and signature stripper, rules prefilter | M1 | Sat 24 Oct, 10:45 to 11:30 | T02 | codex | todo |
| [T04](../tasks/T04-resolvers.md) | DateResolver, EvidenceValidator, Matcher, ConflictDetector | M1 | Sat 24 Oct, 10:45 to 12:00 | T02 | codex | todo |
| [T05](../tasks/T05-fm-extractor.md) | Foundation Models extractor and on-device benchmark screen | M1 | Sat 24 Oct, 11:00 to 12:30 | T03, T04 | codex, then owner on device | todo |
| [T06](../tasks/T06-scx-spike.md) | SCXSwiftKit spike: PlanningModel implementation | M1 | Sat 24 Oct, 10:00 to 11:30 (parallel worktree) | T01 | codex | todo |
| [T07](../tasks/T07-store-today.md) | SwiftData store, seed dataset, Today agenda, item detail | M2 | Sat 24 Oct, 12:30 to 14:00 | T05 | codex | todo |
| [T08](../tasks/T08-review.md) | Review queue | M2 | Sat 24 Oct, 13:30 to 14:30 | T07 | codex | todo |
| [T09](../tasks/T09-share-ocr.md) | Share extension with Vision OCR | M2 | Sat 24 Oct, 14:00 to 15:30 | T07 | codex, then owner on device | todo |
| [T10](../tasks/T10-eventkit.md) | EventKit conflicts, approved event creation, receipts | M3 | Sat 24 Oct, 15:30 to 17:00 | T08 | codex | todo |
| [T11](../tasks/T11-notifications.md) | Local notification reminders | M3 | Sat 24 Oct, 16:30 to 18:00 | T10 | codex | todo |
| [T12](../tasks/T12-pseudonymiser.md) | Pseudonymiser and 'What left my phone' ledger | M4 | Sat 24 Oct, 18:00 to 19:00 | T02 | codex | todo |
| [T13](../tasks/T13-plan-week.md) | Plan my week via SCX MAGPiE | M4 | Sat 24 Oct, 19:00 to 20:00 | T06, T12 | codex | todo |
| [T14](../tasks/T14-voice.md) | ElevenLabs morning briefing | M5 | Sun 25 Oct, 10:00 to 11:00 | T07 | codex, then owner on device | todo |
| [T15](../tasks/T15-app-intents.md) | App Intents for Siri and Shortcuts | M5 | Sun 25 Oct, 10:30 to 12:00 | T07 | codex | todo |
| [T16](../tasks/T16-demo-hardening.md) | Demo hardening | M6 | Sun 25 Oct, 12:00 to 13:00 (code freeze 13:00) | T09, T11, T13, T14 | codex + owner | todo |
| [T17](../tasks/T17-gmail.md) | STRETCH: Gmail fetch from device | Stretch | Only if M3 passes by 17:00 Sat | T10 | codex | todo |
| [T18](../tasks/T18-coreml-triage.md) | STRETCH: Create ML triage classifier | Stretch | Only if ahead of plan | T05 | owner + codex | todo |

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
