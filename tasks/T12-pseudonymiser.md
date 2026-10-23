# T12: Pseudonymiser and 'What left my phone' ledger

| Field | Value |
|---|---|
| Status | in_progress |
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

### Added by manager (2026-10-23)
- [ ] Placeholders are numbered per type in order of first appearance and reused for repeats within one call; the returned map is placeholder to original
- [ ] The Ledger screen is a SwiftUI view in `Recalled/` that takes `[LedgerEntry]` (sample data is fine; the SCX call is out of scope) and compiles on both `Recalled` and `RecalledMac`

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code and tests carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` and `app-build` must be green on `task/T12-pseudonymiser`.

## Verify
```
swift test --package-path RecalledCore
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
SCX call.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
