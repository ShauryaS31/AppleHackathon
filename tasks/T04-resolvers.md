# T04: DateResolver, EvidenceValidator, Matcher, ConflictDetector

| Field | Value |
|---|---|
| Status | done |
| Milestone | M1 |
| Window | Sat 24 Oct, 10:45 to 12:00 |
| Depends on | T02 |
| Assignee | codex |
| Branch | task/T04-resolvers |

## Goal
All deterministic logic the model must never do.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.4 rules; 8 (A2 to A6, A11)

## Acceptance criteria
- [x] `DateResolver.resolve(dueText:sentAt:timeZone:)` returns an exact interval, a date-only deadline, or ambiguous. Uses NSDataDetector plus Calendar in the given time zone. Handles 'tomorrow', weekdays, 'Sat 7pm', '25/10', '25 Oct 2026 6:30pm', relative to sentAt. Australian day/month order
- [x] `EvidenceValidator` passes only if the excerpt is an exact substring of the normalised message and at least 8 chars
- [x] `Matcher` maps an extracted item to an existing Commitment via updatesRef or a title similarity threshold; ambiguous matches return review
- [x] `ConflictDetector` finds overlaps between timed commitments and CalendarEvents; deadlines never conflict
- [x] Applying a reschedule bumps version and keeps the id (A3); cancel sets status cancelled (A4)
- [x] Unit tests for each scenario named above, with fixed time zone Australia/Sydney

### Added by manager (2026-10-23)
- [x] `DateResolver` returns an enum with cases for exact interval (`DateInterval`), date-only deadline (a day in the given time zone) and ambiguous. A time with no end gets a default 1 hour interval. '25/10' is 25 October, never month 25
- [x] `Matcher` rule: lowercase, strip punctuation, token-set Jaccard similarity on titles. At least 0.6 to one existing item is a match; between 0.4 and 0.6, or 0.6 or more to two items, returns review; below 0.4 is new. A valid `updatesRef` always wins over title similarity
- [x] Tests use a fixed `sentAt` and `TimeZone(identifier: "Australia/Sydney")`, never the current clock

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code and tests carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` must be green on `task/T04-resolvers`.

## Verify
```
swift test --package-path RecalledCore
```

## Out of scope
UI, EventKit.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->

## Dev Report (round 1)
- Date: 2026-10-23 14:16 AEDT
- Changed files: `RecalledCore/Sources/RecalledCore/DateResolver.swift`, `EvidenceValidator.swift`, `Matcher.swift`, `ConflictDetector.swift`, `CommitmentUpdater.swift`; `RecalledCore/Tests/RecalledCoreTests/ResolversTests.swift`; `tasks/T04-resolvers.md`; `docs/LOG.md` (append-only entry after the commit attempt).
- What I did: Added deterministic Core date resolution, literal evidence validation, reference/Jaccard matching, overlap detection returning both items, and value-based reschedule/cancel operations. Added 30 Swift Testing tests. No UI, EventKit, model-session, or protected-document changes.
- Acceptance criteria (implemented; runtime verification pending CI):
  - DateResolver API and supported phrases: `resolve(dueText:sentAt:timeZone:)` returns `.exact(DateInterval)`, `.dateOnly(Date)` at local midnight, or `.ambiguous`. Calendar resolves relative days, weekdays, numeric Australian day/month dates and local times. NSDataDetector resolves named dates only after supplying an explicit year and GMT, with Calendar validating components and constructing the requested local day. Covered by `tomorrowAndTodayResolveRelativeToMessageDay`, `weekdaysUseNextOccurrenceIncludingToday`, `saturdaySevenPMDefaultsToOneHour`, `australianDayMonthOrderAndMissingYear`, and `ticketExactTimeUsesSydneyAndExplicitYearA2`.
  - Evidence must be an exact substring of the normalised message and at least 8 characters: only the message is normalised; matching is literal and case sensitive. Covered by `evidenceMustBeExactSubstringOfNormalisedMessageA11` and `evidenceRequiresEightCharactersAndDoesNotNormaliseExcerpt`.
  - Matcher maps to an existing id or returns review/new: valid refs take precedence; stale/unknown refs fall back to title matching. Covered by `validUpdatesReferenceWinsOverTitle`, `unknownAndStaleReferencesFallBackToTitleSimilarity`, and `duplicatedReferenceTargetsNeedReview`.
  - ConflictDetector finds timed overlaps and excludes every deadline: returns both Commitment and CalendarEvent, uses half-open intervals, and excludes the item's own provider event, inactive items and invalid intervals. Covered by `conflictContainsBothItemsA6`, `deadlinesNeverConflictEvenWithTimedFieldsA5`, and the containment, endpoint, invalid-interval and all-day tests.
  - Reschedule retains id and provider id and increments version; cancellation sets cancelled: covered by `rescheduleKeepsIdentityAndBumpsVersionA3`, `dateOnlyRescheduleClearsOldEndAndPreservesTentativeLanguage`, `ambiguousRescheduleAndVersionOverflowRequireReview`, and `cancellationSetsStatusAndPreservesIdentityA4`.
  - Unit tests for the named scenarios: 30 tests in `ResolversTests.swift`, with a fixed 2026-10-23 10:00 Australia/Sydney message timestamp plus explicit fixed boundary dates. All new public functions are exercised.
  - Manager addition, result enum/default duration/Australian order: exact/date-only/ambiguous cases are explicit; missing end defaults to 3,600 seconds; `25/10` resolves to 25 October. Covered by `saturdaySevenPMDefaultsToOneHour`, `namedDateWithoutTimeIsDeadlineA5`, `australianDayMonthOrderAndMissingYear`, and `invalidOrUnderspecifiedDatesNeedReview`.
  - Manager addition, Jaccard rules: lowercase and remove punctuation, then use unique whitespace-separated tokens; >= 0.6 for one id matches, >= 0.4 without a strong match or multiple strong ids requires review, otherwise new. Covered by `matcherLowercasesStripsPunctuationAndUsesSets`, `jaccardThresholdsIncludePointSixAndPointFour`, `twoStrongMatchesRequireReviewRegardlessOfOrdering`, `oneStrongMatchWinsOverWeakerSimilarity`, and the reference tests.
  - Manager addition, fixed clock and Sydney zone: fixtures use `TimeZone(identifier: "Australia/Sydney")` and explicit dates, never the current clock. Includes an independent UTC expectation for A2, local midnight and daylight-saving tests.
- Verify commands run and results: `swift test --package-path RecalledCore` attempted; could not run because `swift` is not installed/recognised on this Windows host. No Swift tests or compilation claimed passed. `git diff --check` passed for tracked changes at the time; separate PowerShell checks of all six new Swift files found no trailing whitespace or current-clock/ambient-calendar references. Core import scan found no FoundationModels, EventKit, UIKit or SwiftUI imports. GitHub Actions `core-tests` on `task/T04-resolvers` remains the required gate.
- Not done / risks / questions for the manager: Apple Foundation/NSDataDetector behavior and Swift 6 compilation still require macOS CI. Unsupported date prose, ambiguous/nonexistent DST times and overnight ranges return review. Bare weekdays include today; missing years choose the next occurrence on or after the message's local day. Review persistence, notification/reminder removal and provider updates are caller responsibilities outside these pure Core helpers; there is no reminder scheduler in the Core models. No toolchain installed. Git writes succeeded and the implementation plus this report were committed on task/T04-resolvers; docs/LOG.md is appended after the commit as instructed.

## Review (round 1)
- Date: 2026-10-23 14:20 AEDT
- Verdict: PASS
- Evidence: core-tests run 39894209979 green (92 tests in the package, 30 in ResolversTests.swift), app-build run 39894209980 green on task/T04-resolvers. Tests use a fixed sentAt and Australia/Sydney, no Date().
- Checked: DateResolver enum (exact, dateOnly, ambiguous), 1 hour default, 25/10 is 25 October, DST gaps and repeats go to ambiguous; EvidenceValidator exact literal substring of the normalised message and at least 8 chars; Matcher Jaccard 0.6 and 0.4 thresholds, two strong matches go to review, valid updatesRef wins; ConflictDetector half-open overlap, deadlines and closed items never conflict; reschedule bumps version and keeps id; cancel sets cancelled.
- Non-blocking, added to T16: DateResolver only accepts the listed shapes. Common forms "by Friday", "on Sat", "this Sat", "Sat 25 Oct", "25 October 2026, 6:30pm", "tonight", "noon" resolve to ambiguous and go to Review. Safe, but noisy.
