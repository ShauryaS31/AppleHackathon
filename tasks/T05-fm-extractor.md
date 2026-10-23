# T05: Foundation Models extractor and on-device benchmark screen

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M1 |
| Window | Sat 24 Oct, 11:00 to 12:30 |
| Depends on | T03, T04 |
| Assignee | codex, then owner on device |
| Branch | task/T05-fm-extractor |

## Goal
Real on-device extraction plus measured speed and accuracy.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.4, 7.7

## Acceptance criteria
- [ ] `FoundationModelsExtractor: CommitmentExtractor` in the app target uses the @Generable types from SPEC 7.4, a fresh LanguageModelSession per message with no tools, and prewarm()
- [ ] Instructions port the Recalled extraction rules (SPEC 7.4) into `ExtractionInstructions.swift`
- [ ] Output mapped to ExtractionDTO then run through EvidenceValidator and DateResolver
- [ ] Handles unavailable model, context overflow and guardrail errors by sending the message to Review
- [ ] Debug screen 'Benchmark' runs 20 bundled fixtures (`Recalled/Resources/benchmark.json`, ported from the web repo's benchmark-gmail-extraction fixtures plus 5 new chat-style ones) and shows per-message time, skipped count, extracted count, evidence failures
- [ ] Owner gate: run on device, paste the numbers into the Dev Report section 'Owner results'

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Persistence.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
