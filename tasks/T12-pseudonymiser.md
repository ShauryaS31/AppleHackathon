# T12: Pseudonymiser and 'What left my phone' ledger

| Field | Value |
|---|---|
| Status | done |
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
- [x] `Pseudonymiser` in RecalledCore: names and organisations via NLTagger, emails, phones, addresses via NSDataDetector, replaced with stable placeholders [P1], [O1], [E1], [T1], [A1]; returns the map
- [x] `rehydrate(text, map)` restores originals
- [x] Unit tests: round trip, same name gets same placeholder, no original value left in output for 10 fixtures
- [x] Ledger screen lists LedgerEntry rows with time, model id, regions, byte count and the exact redacted payload

### Added by manager (2026-10-23)
- [x] Placeholders are numbered per type in order of first appearance and reused for repeats within one call; the returned map is placeholder to original
- [x] The Ledger screen is a SwiftUI view in `Recalled/` that takes `[LedgerEntry]` (sample data is fine; the SCX call is out of scope) and compiles on both `Recalled` and `RecalledMac`

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

## Dev Report (round 1)
- Date: 2026-10-23 14:24 AEDT
- Changed files: `RecalledCore/Sources/RecalledCore/Pseudonymiser.swift`, `RecalledCore/Tests/RecalledCoreTests/PseudonymiserTests.swift`, `Recalled/LedgerView.swift`, `Recalled/ContentView.swift`, `tasks/T12-pseudonymiser.md`; `docs/LOG.md` receives the required handoff entry after the commit attempt.
- What I did: Added local NLTagger person/organisation detection and NSDataDetector email/phone/address detection, per-call placeholder maps, repeat expansion with word boundaries, deterministic overlap handling, and single-pass rehydration. Added 10 test functions, including 10 real-detector fixtures. Added a shared SwiftUI ledger view, populated/empty previews, and an app navigation link (empty until supplied with actual entries).
- Acceptance criteria:
  1. Pseudonymiser and returned map: `pseudonymise(_:)` uses the specified Apple APIs and returns `(text, map)` with P/O/E/T/A tokens; covered by `tenFixturesRemoveOriginalsAndRoundTrip` and `numberingIsPerTypeAndUsesAppearanceNotDetectionOrder`. Written; execution pending CI.
  2. Restore originals: `rehydrate(_:map:)` restores whole tokens without cascading replacements; covered by the round-trip fixtures and `rehydrationUsesWholeTokensAndDoesNotCascade`. Written; execution pending CI.
  3. Required tests: `tenFixturesRemoveOriginalsAndRoundTrip` checks all 10 fixtures for removed originals, expected detected types, and round trips. `repeatedNameUsesOnePlaceholder` checks name reuse. Additional tests cover Unicode, overlaps, reserved tokens, empty input, separate calls and concurrent calls. Written; execution pending CI.
  4. Ledger rows: `LedgerView` displays timestamp including seconds/time zone, model ID, regions, supplied byte count, and the full verbatim selectable payload without a line limit. The existing `redactedPayloadPreview` field must contain the complete transmitted payload. UI inspection/build pending Apple tooling.
  5. Manager numbering/map requirement: counters start at 1 independently per type and reset per call; numbering follows selected spans in input order; exact repeats reuse their placeholder; map keys are placeholders and values are originals. Covered by `numberingIsPerTypeAndUsesAppearanceNotDetectionOrder`, `detectedEmailsNumberInAppearanceOrderAndResetBetweenCalls`, and `concurrentCallsKeepIndependentMaps`. Execution pending CI.
  6. Manager shared-screen requirement: `LedgerView(entries: [LedgerEntry])` is in `Recalled/`, already included by both Recalled and RecalledMac in `project.yml`, and uses shared SwiftUI APIs. Both platform builds remain unverified locally.
- Verify commands run and results: Attempted `swift test --package-path RecalledCore` and `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build`; both could not run because their commands are unavailable on Windows. No Swift tests or Xcode builds are claimed to pass. `git diff --check` passed; a separate whitespace scan included all three new Swift files and found no trailing whitespace.
- Not done / risks / questions for the manager: Manager must push and require green `core-tests` and `app-build` on `task/T12-pseudonymiser` (the existing app-build workflow builds both iOS and macOS). Apple recognition is heuristic and can vary with OS/language; the real-detector fixtures need CI validation. Input containing a reserved placeholder such as `[P1]` throws `reservedPlaceholderInInput` to avoid an ambiguous round trip. Map storage and SCX/region enforcement remain outside this task; the app link has no fabricated sent requests.

## Review (round 1)
- Date: 2026-10-23 14:28 AEDT
- Verdict: PASS
- Evidence: core-tests run 39894985789 green (Test run with 102 tests in the package, 10 in PseudonymiserTests.swift, including tenFixturesRemoveOriginalsAndRoundTrip), app-build run 39894985815 green (Recalled iOS and RecalledMac both compile LedgerView).
- Checked: NLTagger for names and organisations, NSDataDetector for emails (mailto links), phones and addresses; per-type numbering by first appearance, repeats reuse the token; map is placeholder to original; rehydrate is single pass and does not cascade; input that already contains placeholders throws. Ledger screen shows time, model id, regions, byte count and the full redacted payload; reachable from the placeholder screen via "What left my phone" (empty until T13 writes entries).
- Owner check at the M4 gate: NLTagger quality on real names varies by OS model; confirm on device with demo data.
