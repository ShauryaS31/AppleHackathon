# T02: Core models, protocols and fakes

| Field | Value |
|---|---|
| Status | changes_requested |
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

## Review (round 1)
- Date: 2026-10-23 13:58 AEDT
- Verdict: CHANGES
- Evidence: core-tests run 39892340530 and app-build run 39892340489 green on task/T02-core-models. Criteria 1 to 4 and the manager additions are met; the fixes below prevent rework in T03, T04, T05, T12 and T13.

Required fixes:
1. `ReviewItem` (Models.swift) cannot represent a message-level review with no Commitment (over 2,500 tokens, uncertain relevance with zero items, evidence or date failure before a Commitment exists, SPEC 7.4). Make `commitmentId: UUID?` and add `sourceMessageId: String?`; a ReviewItem must have at least one of them (add a failable or precondition-free validating init, your choice, but document it). Add round-trip tests for both shapes.
2. `ExtractionResult.Relevance.none` and `ExtractionResult.Change.none` collide with `Optional.none` (`x?.relevance == .none` silently matches nil). Rename the cases to `irrelevant` and `noChange`. Keep the Codable raw values `"none"` so the wire format still matches SPEC 7.4. Add a test that decodes `"none"` into each.
3. `SourceMessage` decoding must not fail when `labels` or `headers` is missing from the JSON (seed data in T07, App Group handoff in T09). Custom `init(from:)` with `decodeIfPresent`, defaulting to empty. Test: decode a JSON object without those keys.
4. `PseudonymisedPlanRequest` must not reuse `ItemRef`: it would send internal UUIDs and an unscrubbed title to SCX (SPEC 7.5 item 6). Add `PlanItem` (ref like "t3", title, kind, status, dueText, dueStart: Date?, dueEnd: Date?) with no UUID, and use `items: [PlanItem]`. Update tests.
5. `FakeExtractor` and `FakePlanningModel` need a way to throw a scripted error, so error paths can be tested later. Add a test for each.
6. `InMemoryCalendarStore.create` returns deterministic ids `fake-1`, `fake-2`, ... instead of random UUIDs. Update tests.

## Dev Report (round 2)
- Date: 2026-10-23 14:00 AEDT
- Changed files: `RecalledCore/Sources/RecalledCore/Models.swift`, `RecalledCore/Sources/RecalledCore/ServiceModels.swift`, `RecalledCore/Sources/RecalledCore/Fakes.swift`, `RecalledCore/Tests/RecalledCoreTests/ModelsTests.swift`, `RecalledCore/Tests/RecalledCoreTests/FakesTests.swift`, `tasks/T02-core-models.md`; report entry in `docs/LOG.md`.
- What I did: Addressed all six numbered Review (round 1) fixes, with six new regression tests and updates to existing tests. No persistence, UI, protocol signature, or outside-scope changes.
- Acceptance criteria (test coverage below is written, not executed locally):
  - Review fix 1: ReviewItem now supports optional commitment and source-message links. Its documented failable initializer rejects missing links, its decoder rejects invalid JSON, and immutable links preserve the invariant. `evidenceAndReviewItemRetainLinksAndRoundTrip` covers commitment-only reviews; `reviewItemSupportsMessageAndCombinedLinksAndRejectsMissingLinks` covers message-only and combined reviews, round trips, and invalid initialization/decoding.
  - Review fix 2: Relevance.irrelevant and Change.noChange retain the raw value `"none"`. `extractionNoneWireValuesDecodeWithoutOptionalAmbiguity` checks independent wire decoding, encoding, and optional comparisons; existing enum/raw-value round-trip coverage remains.
  - Review fix 3: SourceMessage's custom decoder defaults missing or null labels/headers to empty collections using decodeIfPresent. `sourceMessageDecodesMissingOrNullMetadata` covers both cases; populated metadata still has round-trip coverage.
  - Review fix 4: Added Codable, Sendable, Equatable PlanItem with ref, title, kind, status, dueText, dueStart, and dueEnd, without any UUID. PseudonymisedPlanRequest now takes [PlanItem]. `planningTypesAndItemRefRoundTrip` covers all fields, unresolved dates, round trips, and the exact serialized item key set, excluding internal identifiers. Documentation requires callers to pseudonymise text before construction.
  - Review fix 5: Added Codable, Sendable, Equatable FakeServiceError; FakeExtractor supports per-message scripted errors (taking precedence over results), and FakePlanningModel supports an optional scripted error. `fakeExtractorThrowsScriptedErrorThroughProtocol` and `fakePlanningModelThrowsScriptedErrorThroughProtocol` check exact thrown errors through protocol existentials after serialization; extraction fallback and planning regions are also checked.
  - Review fix 6: Calendar creation uses deterministic per-store ids starting at fake-1 and skips seeded collisions. `inMemoryCalendarStoreCreatesDistinctEventsAndPreservesDrafts` asserts fake-1/fake-2 and independent-store reset; `inMemoryCalendarStoreSkipsSeededProviderIDs` verifies collision avoidance and stored event ids.
  - Original shared-type, supporting-type, protocol, fake, and conformance criteria: all existing models and four Sendable service protocols remain; added types conform to Codable, Sendable, and Equatable. Existing model/fake coverage remains, adjusted for the revised APIs. InMemoryCalendarStore remains a Sendable actor rather than a serialized value model.
  - Source metadata and enum criteria: labels/headers retain their initializer defaults; all specified Commitment.Kind and Commitment.Status raw values are unchanged and covered by `enumRawValuesMatchSpecificationAndRoundTrip`.
  - Platform isolation: static scan of all Core Swift files returned `PASS: no forbidden Core imports` for FoundationModels, EventKit, UIKit, and SwiftUI. A stale-case scan also passed.
- Verify commands run and results: `swift test --package-path RecalledCore` was attempted and exited 1 because PowerShell could not find swift. This Windows environment has no Swift toolchain or Xcode; no installation was attempted, and compilation/tests are not claimed to pass. `git diff --check` passed.
- Not done / risks / questions for the manager: GitHub Actions `core-tests` must be green for these round 2 changes on `task/T02-core-models`; the round 1 green run does not validate them. Pseudonymisation itself remains outside scope. Commit attempt follows this report; its outcome will be recorded here if blocked.
