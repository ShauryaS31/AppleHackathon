# T11: Local notification reminders

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M3 |
| Window | Sat 24 Oct, 16:30 to 18:00 |
| Depends on | T10 |
| Assignee | codex |
| Branch | task/T11-notifications |

## Goal
Reminders that actually fire.

## Read
AGENTS.md; docs/SPEC.md: SPEC 6 M5; 8 (A4)

## Acceptance criteria
- [ ] Permission request flow
- [ ] Confirmed timed items schedule a notification (default 60 min before, setting to change); deadlines notify 09:00 on the day
- [ ] Reschedule replaces, cancel removes the pending notification
- [ ] UI distinguishes 'scheduled' from 'delivered'

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Push notifications.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
