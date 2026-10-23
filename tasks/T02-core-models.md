# T02: Core models, protocols and fakes

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M1 |
| Window | Sat 24 Oct, 10:00 to 10:45 |
| Depends on | T01 |
| Assignee | codex |
| Branch | task/T02-core-models |

## Goal
Define the shared types and platform protocols so app and tests share one vocabulary.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.2, 7.3

## Acceptance criteria
- [ ] Types in RecalledCore: SourceMessage, Commitment (with Kind and Status enums from SPEC 7.3), Evidence, ReviewItem, LedgerEntry, ActionReceipt, ItemRef, CalendarEvent, EventDraft, plus a plain `ExtractionDTO` mirroring SPEC 7.4 (Core cannot import FoundationModels)
- [ ] Protocols CommitmentExtractor, CalendarStore, PlanningModel, Speech as in SPEC 7.2, all Sendable
- [ ] Fakes: FakeExtractor (returns scripted results), InMemoryCalendarStore, FakePlanningModel (configurable regions), SilentSpeech
- [ ] All types Codable, Sendable, Equatable; unit tests cover Codable round trip and fake behaviour

## Verify
```
swift test --package-path RecalledCore
```

## Out of scope
Persistence, UI.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
