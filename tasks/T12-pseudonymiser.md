# T12: Pseudonymiser and 'What left my phone' ledger

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M4 |
| Window | Sat 24 Oct, 18:00 to 19:00 |
| Depends on | T02 |
| Assignee | codex |
| Branch | task/T12-pseudonymiser |

## Goal
Make the privacy claim provable on screen.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.5 item 6; 8 (A9)

## Acceptance criteria
- [ ] `Pseudonymiser` in RecalledCore: names and organisations via NLTagger, emails, phones, addresses via NSDataDetector, replaced with stable placeholders [P1], [O1], [E1], [T1], [A1]; returns the map
- [ ] `rehydrate(text, map)` restores originals
- [ ] Unit tests: round trip, same name gets same placeholder, no original value left in output for 10 fixtures
- [ ] Ledger screen lists LedgerEntry rows with time, model id, regions, byte count and the exact redacted payload

## Verify
```
swift test --package-path RecalledCore
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
SCX call.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
