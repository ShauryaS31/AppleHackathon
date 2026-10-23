# T07: SwiftData store, seed dataset, Today agenda, item detail

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M2 |
| Window | Sat 24 Oct, 12:30 to 14:00 |
| Depends on | T05 |
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

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Share extension, EventKit.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
