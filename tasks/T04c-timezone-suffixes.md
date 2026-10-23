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
- [ ] A trailing zone after a time is recognised (case insensitive, optional "at", optional comma before it): IANA identifiers ("Australia/Sydney", "Europe/London"); "<City> time" for Sydney, Melbourne, Canberra, Hobart, Brisbane, Adelaide, Darwin, Perth, Auckland, London, Singapore; abbreviations AEDT (UTC+11), AEST (UTC+10), ACDT (UTC+10:30), ACST (UTC+9:30), AWST (UTC+8), NZDT (UTC+13), NZST (UTC+12), UTC and GMT (UTC+0). Examples that must work: "10:00 AM Australia/Sydney", "14 October 2026 at 10:00 AM Australia/Sydney", "17:00 Sydney time", "Tuesday 20 October at 17:00 Sydney time", "6pm AEDT", "9am UTC", "3pm Perth time", "Friday 16 October, 16:30–17:00 Sydney time"
- [ ] The wall-clock time is interpreted in the source zone on the stated day, then the resulting instants are returned unchanged (a `Date` is absolute); `DateInterval` start and end are correct for the user's zone. Test: "9am UTC" on a Sydney date gives 20:00 Sydney the same day (AEDT); "3pm Perth time" gives 18:00 Sydney (AEDT); "6pm AEDT" sent from a user in Australia/Perth gives 15:00 Perth
- [ ] Which calendar day "Friday" or "tomorrow" means is decided in the user's zone (sentAt's local day), as today; only the clock time uses the source zone
- [ ] A date-only phrase with a zone ("14 October 2026 Sydney time") stays dateOnly on that day
- [ ] Unknown suffixes ("6pm EST-ish", "3pm Mars time", "9am PST" since US abbreviations are ambiguous) return ambiguous
- [ ] Source zone is kept: add `public static func resolveDetailed(dueText:sentAt:timeZone:) -> (resolution: Resolution, sourceTimeZone: TimeZone?)`; `resolve` stays and returns `.resolution`. `InboxPipeline` stores `sourceTimeZone?.identifier ?? timeZone.identifier` (abbreviations as fixed-offset identifiers such as "GMT+1100") in `Commitment.timezone`; test it
- [ ] All existing T04 and T04b tests pass unchanged
- [ ] Re-run the benchmark agreement: update the ported fixtures in `benchmark.json` that now resolve (set their expectations and remove "Review" from their `name`) so `BenchmarkFixtureTests` passes. In the Dev Report, list each of the 15 ported fixtures with "resolves" or "still Review" and the reason, and give the count that still goes to Review

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code and tests carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` must be green on `task/T04c-timezone-suffixes` (app-build must stay green too).

## Verify
```
swift test --package-path RecalledCore
```

## Out of scope
Displaying the source zone in the UI, US time zone abbreviations, natural-language zones other than the cities listed.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
