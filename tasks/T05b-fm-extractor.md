# T05b: Foundation Models extractor and on-device benchmark screen

| Field | Value |
|---|---|
| Status | blocked |
| Milestone | M1 |
| Window | When the Mac arrives |
| Depends on | T05a, T09 |
| Assignee | codex, then owner on device |
| Branch | task/T05b-fm-extractor |

## Goal
Real on-device extraction plus measured speed and accuracy.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.4, 7.7

## Acceptance criteria
- [ ] `FoundationModelsExtractor: CommitmentExtractor` in the app target uses the @Generable types from SPEC 7.4, a fresh LanguageModelSession per message with no tools, and prewarm()
- [ ] Uses `ExtractionInstructions.instructions` and `ExtractionInstructions.prompt(...)` from T05a unchanged (changes to the wording are a separate, logged decision)
- [ ] Replaces `PendingModelExtractor` from T09 as the app's extractor in one place; the pipeline (`InboxPipeline`) is unchanged
- [ ] Output mapped to ExtractionDTO then run through EvidenceValidator and DateResolver
- [ ] Handles unavailable model, context overflow and guardrail errors by sending the message to Review
- [ ] Debug screen 'Benchmark' runs the 20 fixtures in `Recalled/Resources/benchmark.json` (from T05a) through `InboxPipeline` with the real extractor, compares with `expected`, and shows per-message time, skipped count, extracted count, evidence failures
- [ ] Owner gate: run on device, paste the numbers into the Dev Report section 'Owner results'

Blocked until the Mac and device are available (owner decision 2026-10-23). Split from T05: T05a did the instructions and fixtures.

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Persistence.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
