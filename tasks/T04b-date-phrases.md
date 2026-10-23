# T04b: DateResolver: common date phrasings

| Field | Value |
|---|---|
| Status | todo |
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
- [ ] Leading filler words are ignored: "by", "on", "this", "due", "before" (so "by Friday" = "Friday", "this Sat 7pm" = "Sat 7pm", "due 25 Oct" = "25 Oct")
- [ ] "by Friday" resolves to dateOnly on the next Friday on or after sentAt's local day (same rule as a bare weekday)
- [ ] "Sat 25 Oct" and "Saturday 25 October 2026" resolve to 25 October; when the weekday does not match that date in the given time zone, the result is ambiguous
- [ ] "25 Oct" keeps working (next occurrence on or after sentAt's local day), including with a time and with a comma: "25 Oct, 6:30pm" and "25 October 2026, 6:30pm"
- [ ] "Friday 3pm" and "Friday at 3pm" resolve to an exact 1 hour interval at 15:00 on that Friday
- [ ] "tonight" alone resolves to dateOnly today (no invented time). "tonight at 8" and "tonight 8:30" resolve to exact intervals at 20:00 and 20:30 (a bare hour after "tonight" means pm). "tonight 7pm" works too
- [ ] "noon" and "midday" mean 12:00 wherever a time is accepted ("Friday noon", "tomorrow at midday")
- [ ] "next week Tue", "Tue next week" and "next week Tuesday" resolve to dateOnly on the Tuesday of the calendar week after sentAt's week, weeks starting Monday (en-AU). With a time ("next week Tue 2pm") the result is exact
- [ ] "end of month", "end of the month" and "EOM" resolve to dateOnly on the last day of sentAt's local month
- [ ] Anything not covered still returns ambiguous; add tests for at least 5 unknown phrasings (for example "sometime soon", "after the exam", "Sat or Sun", "next Friday-ish", "the 32nd")
- [ ] All T04 tests still pass unchanged. New tests use a fixed sentAt and `Australia/Sydney`, at least one test per bullet above, including a sentAt on a Friday (for "by Friday"), a Sunday (for "next week Tue") and the last day of a month (for "end of month")

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code and tests carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` must be green on `task/T04b-date-phrases`.

## Verify
```
swift test --package-path RecalledCore
```

## Out of scope
Recurring dates, date ranges across days, other languages, UI.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
