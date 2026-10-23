# T04: DateResolver, EvidenceValidator, Matcher, ConflictDetector

| Field | Value |
|---|---|
| Status | in_progress |
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
- [ ] `DateResolver.resolve(dueText:sentAt:timeZone:)` returns an exact interval, a date-only deadline, or ambiguous. Uses NSDataDetector plus Calendar in the given time zone. Handles 'tomorrow', weekdays, 'Sat 7pm', '25/10', '25 Oct 2026 6:30pm', relative to sentAt. Australian day/month order
- [ ] `EvidenceValidator` passes only if the excerpt is an exact substring of the normalised message and at least 8 chars
- [ ] `Matcher` maps an extracted item to an existing Commitment via updatesRef or a title similarity threshold; ambiguous matches return review
- [ ] `ConflictDetector` finds overlaps between timed commitments and CalendarEvents; deadlines never conflict
- [ ] Applying a reschedule bumps version and keeps the id (A3); cancel sets status cancelled (A4)
- [ ] Unit tests for each scenario named above, with fixed time zone Australia/Sydney

### Added by manager (2026-10-23)
- [ ] `DateResolver` returns an enum with cases for exact interval (`DateInterval`), date-only deadline (a day in the given time zone) and ambiguous. A time with no end gets a default 1 hour interval. '25/10' is 25 October, never month 25
- [ ] `Matcher` rule: lowercase, strip punctuation, token-set Jaccard similarity on titles. At least 0.6 to one existing item is a match; between 0.4 and 0.6, or 0.6 or more to two items, returns review; below 0.4 is new. A valid `updatesRef` always wins over title similarity
- [ ] Tests use a fixed `sentAt` and `TimeZone(identifier: "Australia/Sydney")`, never the current clock

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code and tests carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` must be green on `task/T04-resolvers`.

## Verify
```
swift test --package-path RecalledCore
```

## Out of scope
UI, EventKit.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
