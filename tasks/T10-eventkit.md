# T10: EventKit conflicts, approved event creation, receipts

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M3 |
| Window | Sat 24 Oct, 15:30 to 17:00 |
| Depends on | T08 |
| Assignee | codex |
| Branch | task/T10-eventkit |

## Goal
Real action: approved items become real calendar events.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.5 items 4 and 5; 8 (A6, A12)

## Acceptance criteria
- [ ] `EventKitCalendarStore: CalendarStore` with full-access request flow and clear denied state
- [ ] Conflicts from ConflictDetector shown on Today and in Detail using the next 14 days of events
- [ ] 'Add to Calendar' on a confirmed item shows the exact event (title, time, location) before writing; writes; stores the event identifier and an ActionReceipt
- [ ] Rechecks for overlap immediately before writing
- [ ] A reschedule of an item that already has an event updates that event, not a new one

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Reminders app integration.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
