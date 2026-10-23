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

### Added by manager (2026-10-23)
- [ ] Also define the types the SPEC 7.2 protocols reference: `ExtractionResult` (items plus a relevance flag), `PseudonymisedPlanRequest`, `PlanResponse`
- [ ] `SourceMessage` also carries `labels: [String]` (Gmail label ids, empty for share and seed) and `headers: [String: String]` (empty when unknown), so T03 can prefilter without changing this type
- [ ] `Commitment.Status` raw values match SPEC 7.3 exactly: candidate, tentative, confirmed, completed, cancelled, superseded, needsReview. `Commitment.Kind`: event, deadline, commitment
- [ ] No file in RecalledCore imports FoundationModels, EventKit, UIKit or SwiftUI

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code and tests carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` must be green on `task/T02-core-models`.

## Verify
```
swift test --package-path RecalledCore
```

## Out of scope
Persistence, UI.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
