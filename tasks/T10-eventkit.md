# T10: EventKit conflicts, approved event creation, receipts

| Field | Value |
|---|---|
| Status | in_progress |
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

### Added by manager (2026-10-23)
- [ ] `CalendarStore` in RecalledCore gains `update(_ id: String, with draft: EventDraft) async throws`; `InMemoryCalendarStore` implements it, with unit tests (update keeps the id, unknown id throws)
- [ ] `EventDraft` and `CalendarEvent` gain `location: String?` (default nil, Codable stays backward compatible: missing key decodes as nil, with a test). The preview shows location only when present; Commitment has no location yet, so it is usually empty
- [ ] Info.plist on both app targets has `NSCalendarsFullAccessUsageDescription`; RecalledMac entitlements add `com.apple.security.personal-information.calendars`
- [ ] T07's InMemoryCalendarStore is replaced by `EventKitCalendarStore` in one place; a DEBUG-only switch keeps the in-memory store available for previews
- [ ] Date-only deadlines are never written as timed events (A5); if the user adds one to the calendar it is an all-day event
- [ ] Builds on both `Recalled` and `RecalledMac`

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` and `app-build` must be green on `task/T10-eventkit`. Criteria that need a running app are reviewed as compile-checked and marked PENDING DEVICE; the manager adds them to the "Mac gate checklist" in docs/PLAN.md.

```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Reminders app integration.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
