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

## Dev Report (round 1)
- Date: 2026-10-23 16:56 AEDT
- Changed files: `Recalled/Calendar/EventKitCalendarStore.swift`, `Recalled/Calendar/CalendarApprovalView.swift`, `Recalled/Persistence/CalendarActions.swift`, `Recalled/Persistence/AppStore.swift`, `Recalled/CommitmentDetailView.swift`, `Recalled/ContentView.swift`, `Recalled/ReviewQueueView.swift`, `RecalledCore/Sources/RecalledCore/CalendarAction.swift`, `RecalledCore/Sources/RecalledCore/Protocols.swift`, `RecalledCore/Sources/RecalledCore/ServiceModels.swift`, `RecalledCore/Sources/RecalledCore/Fakes.swift`, `RecalledCore/Sources/RecalledCore/Models.swift`, `RecalledCore/Tests/RecalledCoreTests/CalendarActionTests.swift`, `RecalledCore/Tests/RecalledCoreTests/CalendarStoreUpdateTests.swift`, `RecalledCore/Tests/RecalledCoreTests/FakesTests.swift`, `RecalledCore/Tests/RecalledCoreTests/ModelsTests.swift`, `project.yml`, this task report; completion log entry in `docs/LOG.md`.
- What I did: Added an actor-isolated EventKit adapter and one default service factory, an explicit calendar approval sheet, fresh overlap checks, linked-event updates, and saved provider identifiers plus create/update receipts. The action layer accepts typed commitments and already resolved dates; it never reads message bodies or infers attendees. Added 11 Core tests and extended existing fake/model tests. A successful external write with a failed local save has a receipt-only retry and blocks further calendar writes until that retry succeeds.
- Acceptance criteria (implementation reviewed statically; no Swift compilation or runtime validation was available locally):
  1. `EventKitCalendarStore: CalendarStore`, full access, denied state: implemented in `EventKitCalendarStore.swift`; concurrent requests share one permission task, reads/writes require full access, and denied/restricted/read-only-calendar/missing-event errors reach the UI. PENDING CI / PENDING DEVICE for grant, deny, restriction, write-only upgrade, and retry after changing Settings.
  2. Conflicts on Today and Detail, next 14 days: both query from today's start through 14 calendar days and call `ConflictDetector`; Today names overlapping events, Detail shows their titles/times. Detail also checks when entered through Review. PENDING DEVICE for A6 and foreground refresh.
  3. Exact approval preview, write, identifier, receipt: the sheet shows title, start/end or all-day date, explicit time zone, and optional location. Only its approval button invokes the write. The provider ID and `StoredActionReceipt` save together in SwiftData; Detail shows receipts. `calendarDraftPreservesResolvedTimesWithoutParsingText` and `calendarDraftRejectsEveryUnconfirmedStatus` cover Core draft boundaries. PENDING DEVICE for A12, cancel-without-writing, persistence after relaunch, double-click prevention, and receipt-only retry.
  4. Immediate overlap recheck: `approveCalendar` fetches the exact draft interval again immediately before create/update, checks the commitment snapshot again, and returns a refreshed preview without writing when overlaps differ. The user must approve again. `calendarApprovalOverlapsExcludeOwnEventAndBoundaryTouches` and `calendarApprovalChecksAllDayDeadlineBlock` cover overlap inputs; the application approval/recheck sequence is PENDING DEVICE.
  5. Reschedule updates existing event: approval selects `update(existingID, with:)` when the commitment has a provider ID; the adapter fetches and saves that event with `.thisEvent`, throwing if it is missing instead of creating a replacement. Added `.updateEvent` receipts. `reschedulingUpdatesTheLinkedEventWithoutCreatingADuplicate` covers the Core/store path. Real EventKit update and receipt display are PENDING DEVICE.
  6. Core update API and fake: added the required async throwing protocol method. `calendarUpdatePreservesIDAndReplacesEveryDraftField` checks ID retention and replacement/clearing of fields; `calendarUpdateUnknownIDThrowsWithoutCreatingAnEvent` checks unknown IDs.
  7. Optional location and backward-compatible Codable: both initializers default to nil; synthesized optional decoding accepts absent/null keys. `calendarLocationsDecodeMissingAndNullKeysAndRoundTrip` covers old JSON, null, populated location, and round trips; the existing fake-create test now checks location preservation. Preview conditionally displays nonempty location; commitments currently supply none.
  8. Permissions on both targets: `project.yml` generates `NSCalendarsFullAccessUsageDescription` in both app Info.plists and the macOS calendars entitlement. Generated files are gitignored and produced by XcodeGen in CI. Actual generated output/build is PENDING CI.
  9. Default store replacement and preview switch: `AppStore.makeCalendarStore` defaults to EventKit. Set `RECALLED_DEMO_CALENDAR=1` in a Debug run/preview environment to use seeded `InMemoryCalendarStore`; Release ignores that switch. Explicit service injection remains available. Demo resets only replace the in-memory store when that Debug mode is selected. PENDING CI / PENDING DEVICE.
  10. Date-only deadlines: draft construction makes a one-day all-day event only after explicit approval; it never invents a timed block. `dateOnlyDeadlineCreatesOneCalendarDayAcrossDST` covers the 23-hour Sydney DST day. `explicitlyTimedDeadlineKeepsItsResolvedTime` and `calendarDraftRejectsUnresolvedOrInvalidDatesAndZones` cover timed and invalid cases. PENDING DEVICE for Calendar rendering/A5.
  11. Both app targets: shared sources and generated configuration cover Recalled and RecalledMac. Builds remain PENDING CI; not claimed passed.
- Verify commands run and results:
  - `swift test --package-path RecalledCore`: attempted; could not run (`swift` CommandNotFoundException). Tests are written but not executed locally.
  - `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build`: attempted; could not run (`xcodebuild` CommandNotFoundException).
  - `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build`: attempted; could not run (`xcodebuild` CommandNotFoundException).
  - `git diff --check`: passed. Static import scan found no FoundationModels/EventKit/UIKit/SwiftUI imports in Core.
  - Apple API references checked: [full-access request](https://developer.apple.com/documentation/eventkit/ekeventstore/requestfullaccesstoevents%28completion%3A%29), [EventKit store access and entitlement](https://developer.apple.com/documentation/eventkit/accessing-the-event-store), [authorization status](https://developer.apple.com/documentation/EventKit/EKAuthorizationStatus).
- Not done / risks / questions for the manager: Windows has no Swift toolchain or Xcode; neither was installed. Manager must run/push the `core-tests` and `app-build` gates on `task/T10-eventkit` and add the PENDING DEVICE cases above to the Mac gate checklist. EventKit and SwiftData cannot share a transaction: receipt retry prevents duplicate writes within the running process, but process termination between an external save and local persistence can leave an unlinked event. External Calendar changes can also occur after the final fetch because EventKit offers no atomic conflict-check-and-save. No reminders integration, extraction changes, protected planning/spec edits, merge, or next task was attempted.
- Commit outcome: `git add` returned success, but `git commit -m "T10: add approved EventKit writes, conflicts, and receipts"` failed with `fatal: Unable to create 'C:/Users/User/Desktop/projects/AppleHackathon/.git/index.lock': Permission denied`. All T10 changes are uncommitted; the manager must stage the final report/log updates and commit. Stopping as instructed; no sandbox workaround attempted.
