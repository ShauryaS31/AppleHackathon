# T08: Review queue

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M2 |
| Window | Sat 24 Oct, 13:30 to 14:30 |
| Depends on | T07 |
| Assignee | codex |
| Branch | task/T08-review |

## Goal
Uncertain items get resolved by the user, never guessed.

## Read
AGENTS.md; docs/SPEC.md: SPEC 5 step 3; 8 (A1, A11)

## Acceptance criteria
- [ ] Review tab lists items with reason (ambiguous date, tentative, evidence mismatch, possible duplicate)
- [ ] Actions: Confirm, Edit date/time (picker), Dismiss, Mark as same as existing item
- [ ] Confirm moves status to confirmed and updates Today
- [ ] Badge count on tab

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
EventKit writes.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
