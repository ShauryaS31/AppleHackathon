# T10: EventKit conflicts, approved event creation, receipts

| Field | Value |
|---|---|
| Status | changes_requested |
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
- [x] `EventKitCalendarStore: CalendarStore` with full-access request flow and clear denied state
- [x] Conflicts from ConflictDetector shown on Today and in Detail using the next 14 days of events
- [x] 'Add to Calendar' on a confirmed item shows the exact event (title, time, location) before writing; writes; stores the event identifier and an ActionReceipt
- [x] Rechecks for overlap immediately before writing
- [x] A reschedule of an item that already has an event updates that event, not a new one

### Added by manager (2026-10-23)
- [x] `CalendarStore` in RecalledCore gains `update(_ id: String, with draft: EventDraft) async throws`; `InMemoryCalendarStore` implements it, with unit tests (update keeps the id, unknown id throws)
- [x] `EventDraft` and `CalendarEvent` gain `location: String?` (default nil, Codable stays backward compatible: missing key decodes as nil, with a test). The preview shows location only when present; Commitment has no location yet, so it is usually empty
- [x] Info.plist on both app targets has `NSCalendarsFullAccessUsageDescription`; RecalledMac entitlements add `com.apple.security.personal-information.calendars`
- [x] T07's InMemoryCalendarStore is replaced by `EventKitCalendarStore` in one place; a DEBUG-only switch keeps the in-memory store available for previews
- [x] Date-only deadlines are never written as timed events (A5); if the user adds one to the calendar it is an all-day event
- [x] Builds on both `Recalled` and `RecalledMac`

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

## Review (round 1)
- Date: 2026-10-23 17:00 AEDT
- Verdict: CHANGES
- Evidence: core-tests run 39908678949 green; app-build run 39908678976 FAILED: `Recalled/Persistence/CalendarActions.swift:70:26: error: left side of mutating operator isn't mutable: 'calendarRevision' setter is inaccessible`. Otherwise every criterion is met on reading: full-access flow, 14-day conflicts, exact preview before write, recheck with refreshed preview, update of the linked event, receipts only on success, no attendees, Core update and optional location with tests, plist and Mac entitlement, DEBUG-only in-memory switch (RECALLED_DEMO_CALENDAR=1), all-day for date-only deadlines.

Required fixes:
1. Fix the build: `calendarRevision` in AppStore is `private(set)`; expose a small AppStore method (for example `noteCalendarChanged()`) instead of mutating it from the extension. app-build must be green.
2. EventKitCalendarStore.swift `apply` (lines 111 to 112): on update it overwrites `location` and `notes` with the draft's nil, silently deleting what the user added in Calendar, and the preview does not say so (SPEC 7.5 item 4). On update, only set location and notes when the draft value is non-nil.
3. A linked event deleted in Calendar is a dead end: `missingEvent` throws but `calendarEventId` stays set and the button keeps failing. On `missingEvent`, unlink the id and show the normal create preview; writing still needs the user's approval and creates a new receipt.
4. CalendarAction.swift `overlaps`: all-day deadline drafts are treated as 24 hour events and flag every event that day, contradicting ConflictDetector (deadlines never conflict). Return no overlaps for `isAllDay` drafts; update `calendarApprovalChecksAllDayDeadlineBlock`.
5. All-day events: build the start from the deadline's year, month and day in the user's current calendar and set `event.timeZone = nil` for all-day events (floating), so the date never shifts when the commitment's stored zone differs from the device zone (possible since T04c stores source zones). Add a Core test for the date components used.

## Dev Report (round 2)
- Date: 2026-10-23 17:03 AEDT
- Changed files: `Recalled/Persistence/AppStore.swift`, `Recalled/Persistence/CalendarActions.swift`, `Recalled/Calendar/EventKitCalendarStore.swift`, `Recalled/Calendar/CalendarApprovalView.swift`, `RecalledCore/Sources/RecalledCore/CalendarAction.swift`, `RecalledCore/Tests/RecalledCoreTests/CalendarActionTests.swift`, this task file; completion entry in `docs/LOG.md`.
- What I did / numbered review fixes:
  1. Added `AppStore.noteCalendarChanged()` and replaced the extension's direct mutation with that method. A source scan confirms all remaining `calendarRevision += 1` statements are inside AppStore's declaration. The reported inaccessible-setter error is addressed in source; app-build is PENDING CI, not claimed green.
  2. EventKit's `apply` now assigns location and notes only when the draft contains non-nil values, preserving metadata edited in Calendar during an update. Non-nil values (including explicit empty strings) still apply. PENDING DEVICE: edit location/notes in Calendar, reschedule in Recalled, confirm both survive.
  3. Approval catches EventKit `missingEvent` and the fake's `eventNotFound`, revalidates the commitment after the suspended update, clears and saves the linked ID with rollback on failure, and returns a create preview. The sheet explains the deletion and requires another approval; this recovery branch neither writes an event nor creates a receipt. Subsequent approval follows the normal create/overlap-recheck/receipt path. PENDING DEVICE: delete a linked event, approve the update, confirm the ID clears and a create preview appears; cancel and verify no replacement/receipt, then approve creation and verify one new event, ID and create receipt. Also check persistence after relaunch and unlink-save failure rollback.
  4. `CalendarAction.overlaps` returns no overlaps for all-day drafts. Renamed/updated `calendarApprovalIgnoresAllDayDeadlineBlock` to assert no conflicts against both timed and all-day events. Timed overlap and own-event exclusion tests remain in place.
  5. Date-only drafts now extract source-zone date components in the user's calendar and reconstruct that date at local start of day, adding one calendar day for the end. The calendar defaults to `.current` and is injectable for deterministic tests. EventKit assigns nil timeZone for all-day events; the preview omits the fixed-zone label for these floating dates. Added `dateOnlyDeadlinePreservesSourceDateInDeviceCalendar` (Sydney/Los Angeles in both directions) and `dateOnlyDeadlineUsesUsersNonGregorianCalendar`; updated `dateOnlyDeadlineCreatesOneCalendarDayAcrossDST` to inject Sydney explicitly. These tests cover local year/month/day, midnight, next-day end and DST, but have not run locally.
- Acceptance criteria (source inspection only unless stated; round 1 behavior retained):
  1. Full-access CalendarStore and denied state: unchanged adapter permission flow; PENDING CI / PENDING DEVICE.
  2. Conflicts on Today and Detail for the next 14 days: unchanged queries/ConflictDetector; approval now also excludes all-day deadline drafts. Existing timed-overlap tests plus updated all-day test; PENDING DEVICE for A6.
  3. Exact preview, event ID and ActionReceipt: retained approval/save path; missing-event recovery returns a create preview and requires fresh approval before a new create receipt. PENDING DEVICE for A12 and metadata retention.
  4. Immediate overlap recheck: retained fresh fetch on every approval, including approval after unlink; `calendarApprovalOverlapsExcludeOwnEventAndBoundaryTouches` remains coverage for Core overlap logic. Application sequence PENDING DEVICE.
  5. Reschedule updates linked event: retained update path and `reschedulingUpdatesTheLinkedEventWithoutCreatingADuplicate`; only a confirmed missing-event error unlinks and returns to creation approval. PENDING DEVICE.
  6. Core update API/fake: unchanged; `calendarUpdatePreservesIDAndReplacesEveryDraftField` and `calendarUpdateUnknownIDThrowsWithoutCreatingAnEvent` remain in the suite.
  7. Optional location/backward-compatible Codable: unchanged Core models and `calendarLocationsDecodeMissingAndNullKeysAndRoundTrip`; conditional preview retained, EventKit preserves existing metadata for nil drafts.
  8. Both targets' full-access usage descriptions and Mac calendar entitlement: unchanged `project.yml`; generated output/build PENDING CI.
  9. Single default store factory / DEBUG preview switch: unchanged `AppStore.makeCalendarStore` and `RECALLED_DEMO_CALENDAR`; PENDING CI / PENDING DEVICE.
  10. Date-only deadlines: remain all-day and now use floating local dates with no approval overlaps; regression tests named above. PENDING DEVICE for A5 and differing source/device zones.
  11. Both app targets build: inaccessible-setter fix applied; neither target could be compiled here. PENDING CI.
- Verify commands run and results:
  - `swift test --package-path RecalledCore`: attempted; could not run, `swift` CommandNotFoundException.
  - `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build`: attempted; could not run, `xcodebuild` CommandNotFoundException.
  - `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build`: attempted; could not run, `xcodebuild` CommandNotFoundException.
  - `git diff --check`: passed. Static Core import scan found no FoundationModels, EventKit, UIKit or SwiftUI imports. Reviewed all six source/test diffs; no local compilation or runtime results are claimed.
- Not done / risks / questions for the manager: Windows has no Swift toolchain or Xcode; neither was installed. The manager must push and obtain green `core-tests` and `app-build` on `task/T10-eventkit`, and run the PENDING DEVICE cases above. The round 1 external-write/local-receipt crash window and non-atomic overlap check remain. No protected documents, extraction logic, unrelated tasks, or merge were changed.

## Review (round 2)
- Date: 2026-10-23 17:06 AEDT
- Verdict: PASS
- Evidence: core-tests run 39909312713 green (193 tests), app-build run 39909312847 green on task/T10-eventkit.
- Round 1 fixes verified: build fixed via AppStore.noteCalendarChanged(); updates keep Calendar location and notes when the draft has none; a deleted linked event is unlinked and returns a fresh create preview that still needs approval (no write, no receipt until approved); all-day drafts never overlap; all-day events are floating (timeZone nil) and built from date components in the user's calendar.
- Known edge case, moved to T16 as a required item: CalendarAction.draft reads a date-only deadline's day in the commitment's source zone, but DateResolver stores date-only deadlines as midnight in the user's zone, so "due 14 October 2026 UTC" would land on 13 October. Read the components in the user's calendar instead.
- PENDING DEVICE: moved to the Mac gate checklist (T10 rows).
