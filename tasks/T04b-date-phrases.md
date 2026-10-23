# T04b: DateResolver: common date phrasings

| Field | Value |
|---|---|
| Status | in_progress |
| Milestone | M1 |
| Window | Fri 23 Oct (Windows mode) |
| Depends on | T04 |
| Assignee | codex |
| Branch | task/T04b-date-phrases |

## Goal
Real messages say "by Friday" or "Sat 25 Oct", not only the shapes T04 handles. Resolve the common phrasings deterministically, and keep sending anything unknown to Review.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.4 rules; `RecalledCore/Sources/RecalledCore/DateResolver.swift` and its tests in `ResolversTests.swift`

## Acceptance criteria
All in `DateResolver.resolve(dueText:sentAt:timeZone:)`, keeping its signature and `Resolution` enum. Matching ignores case and surrounding whitespace. The model never computes dates; this code does.
- [x] Leading filler words are ignored: "by", "on", "this", "due", "before" (so "by Friday" = "Friday", "this Sat 7pm" = "Sat 7pm", "due 25 Oct" = "25 Oct")
- [x] "by Friday" resolves to dateOnly on the next Friday on or after sentAt's local day (same rule as a bare weekday)
- [x] "Sat 25 Oct" and "Saturday 25 October 2026" resolve to 25 October; when the weekday does not match that date in the given time zone, the result is ambiguous
- [x] "25 Oct" keeps working (next occurrence on or after sentAt's local day), including with a time and with a comma: "25 Oct, 6:30pm" and "25 October 2026, 6:30pm"
- [x] "Friday 3pm" and "Friday at 3pm" resolve to an exact 1 hour interval at 15:00 on that Friday
- [x] "tonight" alone resolves to dateOnly today (no invented time). "tonight at 8" and "tonight 8:30" resolve to exact intervals at 20:00 and 20:30 (a bare hour after "tonight" means pm). "tonight 7pm" works too
- [x] "noon" and "midday" mean 12:00 wherever a time is accepted ("Friday noon", "tomorrow at midday")
- [x] "next week Tue", "Tue next week" and "next week Tuesday" resolve to dateOnly on the Tuesday of the calendar week after sentAt's week, weeks starting Monday (en-AU). With a time ("next week Tue 2pm") the result is exact
- [x] "end of month", "end of the month" and "EOM" resolve to dateOnly on the last day of sentAt's local month
- [x] Anything not covered still returns ambiguous; add tests for at least 5 unknown phrasings (for example "sometime soon", "after the exam", "Sat or Sun", "next Friday-ish", "the 32nd")
- [x] All T04 tests still pass unchanged. New tests use a fixed sentAt and `Australia/Sydney`, at least one test per bullet above, including a sentAt on a Friday (for "by Friday"), a Sunday (for "next week Tue") and the last day of a month (for "end of month")

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code and tests carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` must be green on `task/T04b-date-phrases`.

## Verify
```
swift test --package-path RecalledCore
```

## Out of scope
Recurring dates, date ranges across days, other languages, UI.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->

## Dev Report (round 1)
- Date: 2026-10-23 14:55 AEDT
- Changed files: `RecalledCore/Sources/RecalledCore/DateResolver.swift`, `RecalledCore/Tests/RecalledCoreTests/ResolversTests.swift`, `tasks/T04b-date-phrases.md`; `docs/LOG.md` receives the required handoff entry.
- What I did: Extended deterministic parsing for leading filler words, weekday-qualified named dates, commas before times, tonight, noon/midday, Monday-based next-week weekdays, and month-end phrases. Preserved the public signature, Resolution enum, existing calendar validation, DST checks, and one-hour default. Added 10 test functions; existing T04 tests are unchanged. No model date computation or new imports.
- Acceptance criteria (implementation and test coverage below; Swift tests have NOT been run successfully locally):
  1. Leading filler words: `leadingDateFillerWordsAreIgnored` covers all five words, combined fillers, case/whitespace normalization, and invalid word boundaries.
  2. By Friday: `byFridayIncludesTheMessageFriday` covers Friday morning, Friday at 23:59, and the following Friday when sent on Saturday.
  3. Weekday-qualified dates: `weekdayAttachedToNamedDateMustMatchTheResolvedLocalDate` covers abbreviated/full weekdays and months, explicit/inferred years, timed dates, invalid dates, mismatches, and year rollover. The task's Saturday 25 October 2026 example is ambiguous because that date is Sunday; Saturday 25 October 2025 demonstrates the matching case.
  4. Named dates with commas/time: `namedDatesAcceptCommaBeforeTimeAndInferTheNextOccurrence` covers both requested comma forms, ordinary timed dates, same-day inclusion, and next-year rollover.
  5. Friday times: `fridayTimeWithOrWithoutAtDefaultsToOneHour` asserts 15:00 with a 3,600-second duration for both forms.
  6. Tonight: `tonightOnlyInfersPMWhenATimeIsProvided` covers date-only today, 20:00, 20:30, explicit pm/am, 24-hour time, local midnight, ranges, and invalid times. Bare hours remain ambiguous outside tonight.
  7. Noon/midday: `noonAndMiddayWorkWhereverATimeIsAccepted` covers weekdays, tomorrow, named/numeric dates, tonight, next week, and both range endpoints at 12:00.
  8. Next week: `nextWeekUsesMondayAsTheStartOfTheCalendarWeek` covers all requested word orders, date-only/timed results, Sunday and Monday boundaries, a same-weekday message, year rollover, and a DST transition.
  9. Month end: `endOfMonthUsesTheLocalMonthIncludingItsLastDay` covers all three aliases, the last day at 23:59, a local month boundary, 30/31-day months, February, leap February, and December.
  10. Unknown phrases: `unsupportedDatePhrasingsStillRequireReview` covers 12 unsupported phrases, including all five suggested examples.
  11. Existing tests/fixed fixtures: test diff reports 151 added lines and zero deleted lines. New tests use fixed dates and Australia/Sydney, including Friday, Sunday, and month-end sentAt values. Passing T04/T04b tests remain unverified pending CI.
- Verify commands run and results: `swift test --package-path RecalledCore` attempted; PowerShell exited 1 because `swift` is not recognized. This Windows environment has no Swift toolchain or Xcode; no installation attempted, and no Swift tests claimed as passing. `git diff --check` passed with no output. `git diff --numstat -- RecalledCore/Tests/RecalledCoreTests/ResolversTests.swift` returned 151 additions, 0 deletions.
- Not done / risks / questions for the manager: Manager must push `task/T04b-date-phrases` and require GitHub Actions `core-tests` to be green. Runtime compilation/test verification is pending; no UI, recurring-date, cross-day-range, or other-language work was undertaken.

## Review (round 1)
- Date: 2026-10-23 14:58 AEDT
- Verdict: PASS
- Evidence: core-tests run 39897652689 green (112 tests in the package; 10 new T04b tests in ResolversTests.swift), app-build run 39897652818 green on task/T04b-date-phrases. All T04 tests unchanged.
- Checked by hand: filler words stripped (by, on, this, due, before); weekday plus date validated against the date; comma before time; "tonight" alone is date-only, a bare hour after it is pm; noon and midday as 12:00; "next week Tue" uses a Monday-start week (sent Sun 25 Oct gives Tue 27 Oct, sent Mon 26 Oct gives Tue 3 Nov); end of month uses the local month; unknown phrasings stay ambiguous.
