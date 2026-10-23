# T07: SwiftData store, seed dataset, Today agenda, item detail

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M2 |
| Window | Sat 24 Oct, 12:30 to 14:00 |
| Depends on | T05a |
| Assignee | codex |
| Branch | task/T07-store-today |

## Goal
The main screens with real persisted data.

## Read
AGENTS.md; docs/SPEC.md: SPEC 5 steps 2 and 3; 7.3

## Acceptance criteria
- [ ] SwiftData models for Commitment, Evidence, ReviewItem, LedgerEntry, ActionReceipt in the App Group container, Data Protection complete
- [ ] No full message bodies persisted after processing (only excerpts)
- [ ] `Seed` loads a demo dataset (12 to 20 items across email, WhatsApp, Slack styles, dates relative to today) from a menu action 'Reset demo'
- [ ] Today view: agenda for today and tomorrow, source icon, tentative badge, conflict badge
- [ ] Detail view: fields, evidence excerpt highlighted in its message context, source and captured time
- [ ] Settings: 'Forget all' deletes everything

### Added by manager (2026-10-23)
- [ ] SwiftData `@Model` classes live in the app target and map to and from the RecalledCore structs (`Commitment`, `Evidence`, `ReviewItem`, `LedgerEntry`, `ActionReceipt`) through explicit functions; views work with the Core types or the models, never with raw message bodies
- [ ] If the App Group container is unavailable (for example RecalledMac without a provisioned group), the store falls back to the default SwiftData location and logs it once; the app still works
- [ ] The conflict badge uses `ConflictDetector` with events from an injected `CalendarStore`. In this task that is an `InMemoryCalendarStore` holding 2 to 3 seeded calendar events, one of which overlaps a seeded commitment; T10 swaps in EventKit
- [ ] Seed items use `SourceMessage.Source` values `seed` and cover email, WhatsApp and Slack styles through `sender`, with at least one tentative item, one date-only deadline and one item in Review
- [ ] The Ledger screen from T12 reads persisted `LedgerEntry` rows instead of an empty array
- [ ] Builds on both `Recalled` and `RecalledMac`

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `app-build` (and `core-tests` if RecalledCore changes) must be green on `task/T07-store-today`. Criteria that need a running app are reviewed as compile-checked and marked PENDING DEVICE; the manager adds them to the "Mac gate checklist" in docs/PLAN.md.

```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Share extension, EventKit.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
