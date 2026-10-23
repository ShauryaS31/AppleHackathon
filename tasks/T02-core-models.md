# T02: Core models, protocols and fakes

| Field | Value |
|---|---|
| Status | in_progress |
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

## Dev Report (round 1)
- Date: 2026-10-23 13:55 AEDT
- Changed files: `RecalledCore/Sources/RecalledCore/Models.swift`, `RecalledCore/Sources/RecalledCore/ServiceModels.swift`, `RecalledCore/Sources/RecalledCore/Protocols.swift`, `RecalledCore/Sources/RecalledCore/Fakes.swift`, `RecalledCore/Tests/RecalledCoreTests/ModelsTests.swift`, `RecalledCore/Tests/RecalledCoreTests/FakesTests.swift`, `tasks/T02-core-models.md`; report entry in `docs/LOG.md`.
- What I did: Added public shared value models and initializers, Sendable service protocols, message-id-scripted extraction, actor-isolated in-memory calendar storage, configurable planning responses/regions, and silent speech. Added 17 tests; retained the scaffold and its existing test because the app and share extension use it. No persistence or UI changes.
- Acceptance criteria:
  - Core types: all ten requested shared models plus `ExtractionDTO` are defined in Models.swift and ServiceModels.swift. `ModelsTests` covers their initializers, populated/empty optional fields, and JSON round trips. `extractionDTOAndResultMirrorWireContract` checks the SPEC 7.4 field names against an independent JSON fixture.
  - Protocols: CommitmentExtractor, CalendarStore, PlanningModel and Speech inherit Sendable and retain the SPEC 7.2 signatures, including synchronous planning regions. Fake tests call all four through protocol existentials.
  - Fakes: `fakeExtractorReturnsScriptsAndConfigurableFallbackThroughProtocol` and `defaultFakeExtractorReturnsNoRelevantItems` cover scripted/default results; calendar tests cover creation, distinct provider ids, draft preservation, independent stores, overlapping events, boundary touches and empty ranges; planning and speech tests cover configured/default regions and responses, and empty/nonempty speech input.
  - Codable, Sendable, Equatable: all new data models and nested enums conform; the stateless/value fakes also conform. InMemoryCalendarStore is a Sendable service actor, not a serialized value model. Generic round-trip test constraints check the data conformances at compile time; tests are written but have not run locally.
  - Additional protocol types: ExtractionResult contains relevance, change and extracted items; PseudonymisedPlanRequest and PlanResponse are defined and covered by `planningTypesAndItemRefRoundTrip` and extraction tests. Uncertain relevance remains distinct from none.
  - Source metadata: labels and headers default to empty; `sourceMessagePreservesMetadataAndRoundTrips` covers populated Gmail metadata, and `sourceMessageDefaultsSupportShareAndSeed` covers share/seed defaults.
  - Enum raw values: `enumRawValuesMatchSpecificationAndRoundTrip` asserts all required Kind and Status values, including the exact `needsReview` spelling, and round-trips every enum case.
  - Platform isolation: PowerShell scan of every Core Swift file returned `PASS: no forbidden Core imports` for FoundationModels, EventKit, UIKit and SwiftUI.
- Verify commands run and results: Attempted `swift test --package-path RecalledCore`; PowerShell exited 1 because `swift` is not recognized. This Windows environment has no Swift toolchain or Xcode, so compilation and tests could not run locally; no toolchain installation attempted. Core Swift trailing-whitespace scan passed. `git diff --check` passed for tracked changes at the time of the check (new Swift files were separately scanned).
- Not done / risks / questions for the manager: `core-tests` must pass on `task/T02-core-models` in GitHub Actions before acceptance. SPEC 7.2 names planning request/response types without prescribing their fields: the request carries pseudonymised ItemRefs and instructions; the response carries a summary and ordered refs, without model-computed dates. Pseudonymisation itself is outside this task. Calendar queries use half-open overlap semantics and preserve insertion order. No outside-scope fixes were made.
