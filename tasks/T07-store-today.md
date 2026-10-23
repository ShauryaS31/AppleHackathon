# T07: SwiftData store, seed dataset, Today agenda, item detail

| Field | Value |
|---|---|
| Status | changes_requested |
| Milestone | M2 |
| Window | Sat 24 Oct, 12:30 to 14:00 |
| Depends on | T05a |
| Assignee | codex |
| Branch | task/T07-store-today |

## Goal
The main screens with real persisted data.

## Read
AGENTS.md; docs/SPEC.md: SPEC 5 steps 2 and 3; 7.3

## Acceptance criteria
- [ ] SwiftData models for Commitment, Evidence, ReviewItem, LedgerEntry, ActionReceipt in the App Group container, Data Protection complete
- [ ] No full message bodies persisted after processing (only excerpts)
- [ ] `Seed` loads a demo dataset (12 to 20 items across email, WhatsApp, Slack styles, dates relative to today) from a menu action 'Reset demo'
- [ ] Today view: agenda for today and tomorrow, source icon, tentative badge, conflict badge
- [ ] Detail view: fields, evidence excerpt highlighted in its message context, source and captured time
- [ ] Settings: 'Forget all' deletes everything

### Added by manager (2026-10-23)
- [ ] SwiftData `@Model` classes live in the app target and map to and from the RecalledCore structs (`Commitment`, `Evidence`, `ReviewItem`, `LedgerEntry`, `ActionReceipt`) through explicit functions; views work with the Core types or the models, never with raw message bodies
- [ ] If the App Group container is unavailable (for example RecalledMac without a provisioned group), the store falls back to the default SwiftData location and logs it once; the app still works
- [ ] The conflict badge uses `ConflictDetector` with events from an injected `CalendarStore`. In this task that is an `InMemoryCalendarStore` holding 2 to 3 seeded calendar events, one of which overlaps a seeded commitment; T10 swaps in EventKit
- [ ] Seed items use `SourceMessage.Source` values `seed` and cover email, WhatsApp and Slack styles through `sender`, with at least one tentative item, one date-only deadline and one item in Review
- [ ] The Ledger screen from T12 reads persisted `LedgerEntry` rows instead of an empty array
- [ ] Builds on both `Recalled` and `RecalledMac`

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `app-build` (and `core-tests` if RecalledCore changes) must be green on `task/T07-store-today`. Criteria that need a running app are reviewed as compile-checked and marked PENDING DEVICE; the manager adds them to the "Mac gate checklist" in docs/PLAN.md.

```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Share extension, EventKit.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->

## Dev Report (round 1)
- Date: 2026-10-23 15:13 AEDT
- Changed files: `Recalled/Persistence/StoredModels.swift`, `Recalled/Persistence/AppStore.swift`, `Recalled/Persistence/Seed.swift`, `Recalled/ContentView.swift`, `Recalled/CommitmentDetailView.swift`, `Recalled/SettingsView.swift`, `Recalled/LedgerView.swift`, `Recalled/RecalledApp.swift`, `project.yml`, and this task file.
- What I did: Replaced the placeholder with a persisted Today/Tomorrow agenda, evidence detail, a read-only Review section, Settings, and the existing Ledger screen backed by a SwiftData query. Added five app-only model classes and explicit Core conversions. Store startup uses the App Group, disables CloudKit, applies complete file protection on iOS, and handles unavailable Mac App Groups with a logged fallback. Reset and deletion save explicitly and roll back on failure. Calendar access is injected through `CalendarStore`; the default implementation is `InMemoryCalendarStore`.
- Acceptance criteria:
  1. Five SwiftData models / App Group / complete protection: `StoredCommitment`, `StoredEvidence`, `StoredReviewItem`, `StoredLedgerEntry`, and `StoredActionReceipt` are registered in `AppStore.makeContainer`. The iOS entitlement is `NSFileProtectionComplete`; `protectStore` sets complete protection on the directory and existing database/WAL/SHM files. Static audit found five models. Persistence, relaunch and lock protection: **PENDING DEVICE**, compilation pending CI.
  2. No full message bodies: no body property or `SourceMessage` instance is persisted. Evidence keeps its exact excerpt, metadata, and at most 120 characters of neighboring excerpt on each side. Static audit found zero model body properties. Store inspection: **PENDING DEVICE**.
  3. Reset demo / 12–20 items / relative dates / styles: the menu's `Reset demo` calls `AppStore.resetDemo`, deletes old rows and loads 15 items through `Seed.insert`. Dates resolve through Core `DateResolver` relative to reset time. Static audit: 15 items; Email, WhatsApp and Slack sender styles are present. Repeat reset and relaunch: **PENDING DEVICE**.
  4. Today agenda: `ContentView` queries persisted commitments, shows Today and Tomorrow sections, source icons, Tentative labels and Conflict labels. It excludes completed/cancelled/superseded items, includes interval overlaps across day boundaries, labels date-only deadlines without a fake time, and refreshes the day on activation and while foregrounded. Visual behavior: **PENDING DEVICE**.
  5. Detail: `CommitmentDetailView` displays fields, source, sender, sent/captured times, message reference, bounded context with the exact evidence highlighted, conflict details and review reasons. It also reads persisted receipts. Visual/accessibility review: **PENDING DEVICE**.
  6. Forget all: `SettingsView` confirms deletion, invokes `AppStore.forgetAll`, and surfaces errors. Static audit confirms deletion of all five entity types; the default in-memory calendar is cleared too. Empty queries and no reappearance after relaunch: **PENDING DEVICE**.
  7. App-side models / explicit Core mappings: all five classes have `init` mappings from Core and `toCore()` mappings back; the Review mapping preserves Core's failable validity check. Views use models/Core values only. Static audit found five mappings. RecalledCore was not changed. Runtime round trips: **PENDING DEVICE**.
  8. Unavailable App Group: `groupDirectory` handles a missing group URL and an inaccessible/unwritable Mac group directory. The fallback uses default SwiftData storage with `groupContainer: .none`; a main-actor static guard logs it once. An iOS protected-store error is surfaced rather than silently switching stores. Unprovisioned Mac launch: **PENDING DEVICE**.
  9. Injected calendar / conflict detection: `AppStore.init(calendarStore:)` accepts any Core `CalendarStore`. `ContentView.refreshConflicts` queries it for the agenda interval and calls Core `ConflictDetector`. `Seed.calendarEvents` supplies three events; Existing team meeting overlaps Sprint check-in at today's 10am. Stale async results are discarded and calendar errors are visible. Static audit found three calendar fixtures. Badge and injected-store behavior: **PENDING DEVICE**.
  10. Seed source and edge cases: all evidence is `.seed`, with styles in `sender`. Static audit found three tentative items, two date-only deadlines and one needs-review item; that item gets a persisted `ReviewItem` with a missing-date/time reason. **PENDING DEVICE** for rendered results.
  11. Persisted Ledger: `PersistedLedgerView` queries `StoredLedgerEntry` newest first, maps rows to Core, and passes them to the T12 `LedgerView`. Demo loading does not fabricate outbound requests or action receipts. Insert a ledger row and verify exact payload and relaunch persistence: **PENDING DEVICE**.
  12. Both app targets: shared files remain under `Recalled/`, included by both existing XcodeGen targets. Protection APIs are guarded by `#if os(iOS)` and the new entitlement is only on the iOS app. Both builds are **PENDING CI**, not claimed compile-checked locally.
- Verify commands run and results:
  - `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build`: could not run; PowerShell reported `xcodebuild` is not recognized (exit 1).
  - `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' build`: could not run; same missing-tool error (exit 1).
  - `Get-Command swift,xcodebuild,xcodegen -ErrorAction SilentlyContinue`: no tools found. No toolchain installation attempted.
  - `git diff --check`: passed after normalizing the rewritten file's line ending.
  - PowerShell source audit: passed with ModelClasses=5, CoreMappings=5, SeedItems=15, TentativeItems=3, DateOnlyDeadlines=2, ReviewItems=1, CalendarFixtures=3, DeletedEntityTypes=5, BodyProperties=0. These are source checks, not Swift compilation or runtime tests.
- Not done / risks / questions for the manager: Windows has no Swift/Xcode; no Swift tests, app builds or device checks passed locally. The manager must push `task/T07-store-today` and require `app-build` green for both apps. Core was unchanged. Please add the PENDING DEVICE checks above to the Mac gate checklist, including database/mapping round trips, reset twice, evidence highlighting, conflict badges, unprovisioned Mac fallback, persisted ledger rows, Forget all followed by relaunch, and iPhone file protection/lock behavior. Data Protection complete is iOS-specific; the native Mac build does not use that iOS entitlement/API. Review resolution, ingestion, Share extension and EventKit remain outside T07. Protected project documents were not edited.
- Commit/log outcome: Git staging succeeded in this sandbox. Requested commit message: `T07: Add persisted agenda, evidence detail and demo store`. The LOG line follows the implementation commit, per the task instructions.

## Review (round 1)
- Date: 2026-10-23 15:17 AEDT
- Verdict: CHANGES
- Evidence: core-tests run 39899357316 and app-build run 39899357243 green on task/T07-store-today (compiles on both targets). All six original criteria and the manager additions are met on reading; the fixes below are runtime and data-shape problems a compile check cannot catch, and are cheapest to fix before any data is installed.

Required fixes:
1. ContentView.swift toolbar `Menu`: `NavigationLink`s inside a toolbar Menu often do not push (iOS and macOS), which would make Settings ("Forget all") and the Ledger unreachable. Use Buttons that set state and push with `.navigationDestination(isPresented:)` or a `NavigationPath`.
2. StoredModels.swift `StoredEvidence.contextBefore/contextAfter`: 120 characters per side stores the whole body of any short WhatsApp message, which SPEC 7.3 forbids. Rule: at most 40 characters per side, cut at a word boundary, and store no context at all when the body is shorter than excerpt + 80 characters. Put the rule in one function with a unit-testable signature (pure Swift, no SwiftData), and use it for seed data too.
3. Store `kind`, `status` and receipt `action` as raw `String` properties (`statusRaw` etc.) with computed enum accessors, so T08 and T09 can use `#Predicate` on them. Update Today's queries.
4. `StoredReviewItem` must be displayable without a commitment (message-level review from T02): add `sender: String`, `excerpt: String` (bounded by fix 2's rule), `createdAt: Date`, all with defaults.
5. `AppStore` gets one write API, `ingest(commitments:evidence:reviewItems:)` (insert or update by id, one save), so T09 and T08 never write to `mainContext` directly.
6. RecalledApp.swift: when opening the store fails (for example a launch while the device is locked with complete protection), retry automatically when the scene becomes active, not only through the "Try again" button.

PENDING DEVICE (to the Mac gate checklist after PASS): store files carry NSFileProtectionComplete; data survives relaunch; Reset demo twice gives 15 items, no duplicates, dates relative to today; badges including the Sprint check-in conflict render; excerpt highlight in Detail; menu reaches Settings and Ledger; Forget all then relaunch is empty; unprovisioned RecalledMac falls back and logs once.

## Dev Report (round 2)
- Date: 2026-10-23 15:20 AEDT
- Changed files: `Recalled/ContentView.swift`, `Recalled/Persistence/AppStore.swift`, `Recalled/Persistence/Seed.swift`, `Recalled/Persistence/StoredModels.swift`, `Recalled/RecalledApp.swift`, `RecalledCore/Sources/RecalledCore/EvidenceContext.swift`, `RecalledCore/Tests/RecalledCoreTests/EvidenceContextTests.swift`, and this task file. The requested LOG entry follows the commit if Git can write.
- What I did / numbered review fixes:
  1. Replaced toolbar Menu navigation links with state-setting Buttons and two `.navigationDestination(isPresented:)` destinations for Settings and Ledger.
  2. Added pure Core `EvidenceContext.retained(body:excerpt:)`: no context below excerpt length + 80, at most 40 characters per side, outer cuts at whitespace word boundaries, and no context for empty/missing excerpts. Exact evidence remains unchanged. `StoredEvidence` accepts a transient body, calls this helper, and stores only the resulting fragments; context setters are private. Seed uses the same constructor/rule, so its short messages retain no context. Added five Swift tests covering short messages and the 79-character boundary, exactly 80 additional characters, partial outer words, empty/missing/edge excerpts, oversized words, Unicode and whitespace.
  3. Changed persisted enum storage to `kindRaw`, `statusRaw`, and `actionRaw`, with computed enum getters/setters and explicit Core mappings. Today's SwiftData predicate now excludes completed/cancelled/superseded rows using `statusRaw`.
  4. Added defaulted sender, excerpt, and createdAt to StoredReviewItem. Its preview uses the same 40-character word-boundary helper; no neighboring context is kept. The unlinked Review row renders sender, excerpt and timestamp alongside its reason. Seed supplies these fields too.
  5. Added `AppStore.ingest(commitments:evidence:reviewItems:)`: Core commitments plus detached StoredEvidence/StoredReviewItem inputs, explicit UUID lookup and insert/update for each entity, one save after the whole batch, rollback and rethrow on failure. Evidence/review constructors now accept an explicit row UUID; callers must reuse it for retries/updates because those Core structs have no row ID. All commitment fields and evidence/review metadata are updated.
  6. Store startup observes scenePhase and retries automatically on active when the store is missing. The Try again button shares the same guarded helper; a successful store is not reopened.
- Acceptance criteria (source inspection only; new compilation and runtime results remain pending):
  1. Five SwiftData models / App Group / complete protection: existing schema registration, App Group/fallback configuration and iOS protection remain in place; raw enum columns and defaulted review fields implement the requested schema changes. **PENDING CI / DEVICE**.
  2. No full message bodies: no stored body property; body is a constructor argument only. Shared context limits are covered by `shortMessagesRetainNoNeighboringContext`, `contextThresholdIncludesExactlyEightyAdditionalCharacters`, `contextDropsPartialWordsAtBothOuterEdges`, and `contextHandlesMissingEmptyAndEdgeExcerpts`. Tests are written, **not run locally**.
  3. Reset demo / 12-20 items / relative dates / styles: the existing 15-item dataset, DateResolver calls and menu reset remain; seed evidence now passes through the privacy helper. Reset twice and relaunch: **PENDING DEVICE**.
  4. Today agenda / badges: existing today/tomorrow interval logic, icons and tentative/conflict rendering remain, with terminal statuses filtered by a raw-string SwiftData predicate. **PENDING CI / DEVICE**.
  5. Detail fields / evidence / metadata: existing exact highlighted excerpt and source/capture metadata remain; neighboring context is now limited or absent. **PENDING DEVICE**.
  6. Forget all: Settings is reached through a Button-backed navigation destination; existing deletion of all five entities is unchanged. Navigation and relaunch after deletion: **PENDING DEVICE**.
  7. App-only models / explicit Core mappings: all five models remain in the app target. Only the pure context helper and its tests were added to Core; models retain explicit Core conversions.
  8. Unavailable App Group: existing fallback and log-once behavior remain. Failed store startup additionally retries on activation. Unprovisioned Mac launch and locked iPhone recovery: **PENDING DEVICE**.
  9. Injected calendar / conflict detection: existing CalendarStore injection, three seeded events and ConflictDetector calls remain unchanged. Badge behavior: **PENDING DEVICE**.
  10. Seed source and edge cases: all seed evidence remains `.seed`; sender styles, tentative/date-only items and the linked review remain. Message-level review display is additionally supported; previews are covered by `boundedReviewExcerptHandlesUnicodeWhitespaceAndLongWords` (not run locally).
  11. Persisted Ledger: the existing persisted query remains; its menu route now uses state-driven navigation. **PENDING DEVICE**.
  12. Both app targets: shared app sources and Core package discovery include the changes without project configuration edits. Both builds are **PENDING CI**, not compile-checked locally.
- Verify commands run and results:
  - `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build`: could not run, command not recognized (exit 1).
  - `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' build`: could not run, command not recognized (exit 1).
  - `swift test --package-path RecalledCore`: could not run, command not recognized (exit 1). No toolchain installation attempted.
  - `git diff --check`: passed before report append; final whitespace check is performed before staging.
  - PowerShell source audit: MenuButtonsAndDestinations, SharedContextRule, RawEnumFields, ReviewMetadata, IngestOneSaveAndRollback, AutomaticRetry, FivePureSwiftTests, and NoStoredBodyProperty all True. These checks inspect source and do not execute Swift, SwiftData, or UI behavior.
- Not done / risks / questions for the manager: require fresh green `app-build` for both apps and `core-tests` on this branch; round 1 CI does not validate these edits. Existing PENDING DEVICE items remain, plus message-only review display, same-ID ingestion insert/update/retry (including repeated IDs within one batch and save-failure rollback), raw-string query filtering, and failed-open recovery on scene activation. This changes the development schema before data installation as requested; no migration of round 1 development stores is provided. T08/T09 callers should use ingest and preserve evidence/review row UUIDs. Protected project documents were not edited.
- Commit/log outcome: `git diff --check` and `git diff --cached --check` passed, and staging succeeded. `git commit -m "T07: Address store and Today review fixes"` failed (exit 1): `fatal: Unable to create 'C:/Users/User/Desktop/projects/AppleHackathon/.git/index.lock': Permission denied`. No commit was created. All changes remain uncommitted; this final report update is unstaged. Per the user's explicit instruction for read-only Git failures, stopped here without appending the post-commit LOG line. The manager must stage the final report, commit, and append the LOG entry.
