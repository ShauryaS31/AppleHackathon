# T04c: DateResolver: timezone suffixes

| Field | Value |
|---|---|
| Status | in_progress |
| Milestone | M1 |
| Window | Fri 23 Oct (Windows mode) |
| Depends on | T04b, T09 |
| Assignee | codex |
| Branch | task/T04c-timezone-suffixes |

## Goal
Emails state times with a zone ("10:00 AM Australia/Sydney", "17:00 Sydney time"). Today those go to Review; 8 of the 15 ported benchmark fixtures expect Review only for this reason. Resolve them, convert to the user's time zone, and remember the zone the message used.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.3 (Commitment.timezone), 7.4 rules; `DateResolver.swift`, `InboxPipeline.swift`, `BenchmarkFixtureTests.swift`, `Recalled/Resources/benchmark.json`

## Acceptance criteria
- [x] A trailing zone after a time is recognised (case insensitive, optional "at", optional comma before it): IANA identifiers ("Australia/Sydney", "Europe/London"); "<City> time" for Sydney, Melbourne, Canberra, Hobart, Brisbane, Adelaide, Darwin, Perth, Auckland, London, Singapore; abbreviations AEDT (UTC+11), AEST (UTC+10), ACDT (UTC+10:30), ACST (UTC+9:30), AWST (UTC+8), NZDT (UTC+13), NZST (UTC+12), UTC and GMT (UTC+0). Examples that must work: "10:00 AM Australia/Sydney", "14 October 2026 at 10:00 AM Australia/Sydney", "17:00 Sydney time", "Tuesday 20 October at 17:00 Sydney time", "6pm AEDT", "9am UTC", "3pm Perth time", "Friday 16 October, 16:30–17:00 Sydney time"
- [x] The wall-clock time is interpreted in the source zone on the stated day, then the resulting instants are returned unchanged (a `Date` is absolute); `DateInterval` start and end are correct for the user's zone. Test: "9am UTC" on a Sydney date gives 20:00 Sydney the same day (AEDT); "3pm Perth time" gives 18:00 Sydney (AEDT); "6pm AEDT" sent from a user in Australia/Perth gives 15:00 Perth
- [x] Which calendar day "Friday" or "tomorrow" means is decided in the user's zone (sentAt's local day), as today; only the clock time uses the source zone
- [x] A date-only phrase with a zone ("14 October 2026 Sydney time") stays dateOnly on that day
- [x] Unknown suffixes ("6pm EST-ish", "3pm Mars time", "9am PST" since US abbreviations are ambiguous) return ambiguous
- [x] Source zone is kept: add `public static func resolveDetailed(dueText:sentAt:timeZone:) -> (resolution: Resolution, sourceTimeZone: TimeZone?)`; `resolve` stays and returns `.resolution`. `InboxPipeline` stores `sourceTimeZone?.identifier ?? timeZone.identifier` (abbreviations as fixed-offset identifiers such as "GMT+1100") in `Commitment.timezone`; test it
- [x] All existing T04 and T04b tests pass unchanged
- [x] Re-run the benchmark agreement: update the ported fixtures in `benchmark.json` that now resolve (set their expectations and remove "Review" from their `name`) so `BenchmarkFixtureTests` passes. In the Dev Report, list each of the 15 ported fixtures with "resolves" or "still Review" and the reason, and give the count that still goes to Review

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code and tests carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` must be green on `task/T04c-timezone-suffixes` (app-build must stay green too).

## Verify
```
swift test --package-path RecalledCore
```

## Out of scope
Displaying the source zone in the UI, US time zone abbreviations, natural-language zones other than the cities listed.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->

## Dev Report (round 1)
- Date: 2026-10-23 16:39 AEDT
- Changed files: `RecalledCore/Sources/RecalledCore/DateResolver.swift`, `RecalledCore/Sources/RecalledCore/InboxPipeline.swift`, `RecalledCore/Sources/RecalledCore/CommitmentUpdater.swift`, `RecalledCore/Tests/RecalledCoreTests/DateResolverTimeZoneTests.swift` (new), `RecalledCore/Tests/RecalledCoreTests/InboxPipelineTests.swift`, `Recalled/Resources/benchmark.json`, this task file; `docs/LOG.md` receives the handoff entry after the commit attempt.
- What I did: Added case-insensitive source-zone suffix parsing and the public `resolveDetailed` API; retained `resolve` as its resolution-only wrapper. Day selection and date-only midnight stay in the user's calendar; timed results rebuild that day's year/month/day in the source calendar and preserve absolute instants. Zoned bare times use sentAt's local day; existing unzoned bare-time ambiguity remains unchanged. Added source-zone persistence for new/tentative items and, through the existing CommitmentUpdater path, reschedules/updates. Added focused regression tests and removed obsolete zone-related Review expectations from seven ported fixtures.
- Acceptance criteria (test coverage below is written, not executed locally):
  1. Trailing IANA, city and abbreviation suffixes, case, optional at/comma, and every listed example: `zoneSuffixExamplesAndOptionalSeparators`, `zoneCityNamesKeepCanonicalIdentifiersAndUseSeasonalOffsets`, `zoneAbbreviationsHaveFixedOffsetsInBothSeasons`. All 11 listed cities and nine abbreviations are covered. Canberra maps to Australia/Sydney.
  2. Source wall clocks produce absolute instants with correct user-local starts/ends: `zoneInstantsDisplayCorrectlyInTheUserZoneIncludingRangeEndsAndDayRollover` covers 9am UTC -> 20:00 Sydney, 3pm Perth -> 18:00 Sydney, 6pm AEDT -> 15:00 Perth, range endpoints and next-day rollover. Independent UTC assertions cover seasonal city offsets and fixed abbreviations. `zoneDSTValidationUsesTheSourceCalendar` covers source-zone gaps/overlaps.
  3. Friday/tomorrow/day inference remain user-local: `zoneRelativeDaysAndMissingYearUseTheUsersCalendar` uses a Sydney Friday that is still Thursday in UTC/Perth, tests the reverse source/user direction, and checks missing-year inference.
  4. Zoned date-only phrases stay dateOnly on the user-local day: `zoneDateOnlyStaysOnTheUserDayAndDetailedUnzonedResultsHaveNoSource`, `pipelineZonedDateOnlyStoresSourceZoneWithoutShiftingDeadline`.
  5. Unknown suffixes remain ambiguous: `zoneUnknownSuffixesAndMalformedTimesRemainAmbiguous` includes EST-ish, Mars time, PST, invalid IANA names, invalid dates/times and unsupported trailing prose; `pipelineUnknownZoneRequiresReviewWithoutMutation` covers ingestion.
  6. Source-zone API/storage: `zoneAbbreviationsHaveFixedOffsetsInBothSeasons` checks wrapper parity and fixed offsets; `zoneDateOnlyStaysOnTheUserDayAndDetailedUnzonedResultsHaveNoSource` checks absent source metadata. `pipelineStoresSourceZoneForNewTentativeAndRescheduledItems` covers new/noChange/updated/rescheduled, IANA identifiers, GMT+1100/GMT+1030 and the user-zone fallback. `pipelineDatelessUpdatePreservesExistingSourceZone` protects existing schedules.
  7. Existing T04/T04b tests: `ResolversTests.swift` is unchanged (verified with git diff); execution remains pending on macOS CI. No claim that they passed.
  8. Benchmark agreement: existing `BenchmarkFixtureTests.swift` is unchanged. Updated only names and requiresReview for ported-02/05/06/13/14/15/17; existing expected dates/times already match the intended resolutions. PowerShell JSON audit passed: 20 fixtures, 15 ported, seven zone fixtures changed, one ported fixture still marked Review; every body, evidence excerpt, dueText, date/time label and unrelated field is unchanged. Swift benchmark agreement could not be re-run locally.
- Ported fixture outcomes (expected from code inspection and fixture audit; not a Swift execution result):
  - ported-01: resolves - date-only report deadline, 2026-10-12.
  - ported-02: resolves - Australia/Sydney meeting, 2026-10-14 10:00.
  - ported-03: resolves - irrelevant thanks message; no item/date to resolve and no Review expectation.
  - ported-04: resolves - dateless commitment is valid; no date or Review expectation.
  - ported-05: resolves - cancelled meeting's Australia/Sydney date, 2026-10-14 10:00.
  - ported-06: resolves - report deadline 2026-10-12 plus zoned meeting 2026-10-14 10:00.
  - ported-07: resolves - tomorrow is date-only, 2026-10-11.
  - ported-08: resolves - irrelevant optional newsletter; no item/date to resolve and no Review expectation.
  - ported-09: still Review - uncertain personal obligation, although Friday resolves to 2026-10-16.
  - ported-10: resolves - Friday reschedule, 2026-09-18.
  - ported-11: resolves - date-only report deadline, 2026-10-12; tracking URL fixture unchanged.
  - ported-13: resolves - Sydney range, 2026-10-16 16:30-17:00. Still tentative; InboxPipeline independently creates its existing tentative Review. The benchmark's requiresReview flag measures ambiguous dates/uncertain relevance, not tentative status (as also demonstrated by new-01).
  - ported-14: resolves - Sydney deadline, 2026-10-20 17:00.
  - ported-15: resolves - Sydney range, 2026-10-21 12:00-12:30.
  - ported-17: resolves - Sydney commitment, 2026-10-29 14:00.
- Review count: 1 of 15 remains marked requiresReview in the benchmark (ported-09); zero remain date-ambiguous. If these labels are ingested through InboxPipeline, ported-13 also retains its tentative Review, for two fixtures with Review behavior. The task's stated eight zone-blocked fixtures is a count discrepancy: the baseline contains seven zone-blocked fixtures plus the uncertain ported-09. Tentative/relevance policy was not changed.
- Verify commands run and results: `swift test --package-path RecalledCore` was attempted and could not execute because `swift` is not installed/recognised on Windows; no Swift toolchain or Xcode was installed. The suite and benchmark agreement have NOT passed locally. PowerShell fixture audit passed as described above. Plain `git diff --check` reported CRLF line endings as trailing whitespace in the already-CRLF benchmark JSON; `git -c core.whitespace=cr-at-eol diff --check` passed, preserving that file's existing line endings.
- Not done / risks / questions for the manager: Runtime/compile verification requires GitHub Actions `core-tests` green on `task/T04c-timezone-suffixes`, with `app-build` remaining green. No CI run or app build was performed here. UI display, US abbreviations, and extra natural-language cities remain out of scope. No other task was started.

## Review (round 1)
- Date: 2026-10-23 16:43 AEDT
- Verdict: PASS
- Evidence: core-tests run 39907084666 green (175 tests, new DateResolverTimeZoneTests), app-build run 39907084668 green on task/T04c-timezone-suffixes. All T04 and T04b tests unchanged.
- Checked: suffix parsed only when it is a known zone (fixed-offset AU/NZ abbreviations, UTC, GMT, listed "<City> time", IANA paths); PST and other names stay ambiguous; day words resolved in the user's zone, clock time in the source zone; resolveDetailed returns the source zone and InboxPipeline and CommitmentUpdater store it in Commitment.timezone.
- Fixture re-run: 0 of 15 ported fixtures now go to Review for a date (was 7; the brief said 8, the developer's count of 7 is correct). ported-09 still expects Review for uncertain relevance; ported-13 still gets the pipeline's tentative review.
