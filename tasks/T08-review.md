# T08: Review queue

| Field | Value |
|---|---|
| Status | changes_requested |
| Milestone | M2 |
| Window | Sat 24 Oct, 13:30 to 14:30 |
| Depends on | T07 |
| Assignee | codex |
| Branch | task/T08-review |

## Goal
Uncertain items get resolved by the user, never guessed.

## Read
AGENTS.md; docs/SPEC.md: SPEC 5 step 3; 8 (A1, A11)

## Acceptance criteria
- [ ] Review tab lists items with reason (ambiguous date, tentative, evidence mismatch, possible duplicate)
- [ ] Actions: Confirm, Edit date/time (picker), Dismiss, Mark as same as existing item
- [ ] Confirm moves status to confirmed and updates Today
- [ ] Badge count on tab

### Added by manager (2026-10-23)
- [ ] Message-level review items (no commitment, from T02 round 2) show the sender, time and an excerpt of the stored evidence or the review reason, with actions Dismiss and "Create item" (title, kind, date/time picker); no message body is persisted to do this
- [ ] "Mark as same as existing item" lets the user pick an open item; the existing item keeps its id, takes the candidate's due fields and evidence, and bumps version (as in A3); the candidate becomes `superseded`
- [ ] Every action removes the ReviewItem and updates Today without a relaunch
- [ ] Builds on both `Recalled` and `RecalledMac`

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `app-build` (and `core-tests` if RecalledCore changes) must be green on `task/T08-review`. Criteria that need a running app are reviewed as compile-checked and marked PENDING DEVICE; the manager adds them to the "Mac gate checklist" in docs/PLAN.md.

```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
EventKit writes.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->

## Dev Report (round 1)
- Date: 2026-10-23 15:29 AEDT
- Changed files: `Recalled/ContentView.swift`, `Recalled/ReviewQueueView.swift` (new), `Recalled/Persistence/ReviewActions.swift` (new), `Recalled/Persistence/Seed.swift`, `tasks/T08-review.md`; `docs/LOG.md` receives the required handoff entry.
- What I did: Added a dedicated Review tab, source summaries and a resolution sheet. Added main-actor store actions that save commitment/evidence changes and review deletion together, rolling back on errors. Added validation for missing dates, invalid time ranges, blank titles, stale/closed candidates, invalid merge targets and version overflow. Demo reset now queues tentative plans as well as the ambiguous lunch. No Core changes or EventKit writes.
- Acceptance criteria (implementation inspected; compilation PENDING CI and all runtime checks PENDING DEVICE):
  1. Review lists reasons: `ReviewQueueView` renders every stored reason, including ambiguous date, tentative, evidence mismatch and possible duplicate; it does not filter by reason. Seed generates tentative and ambiguous examples. PENDING DEVICE: inspect all four reason types, including externally ingested mismatch/duplicate rows.
  2. Confirm, Edit date/time, Dismiss, Mark as same: resolution sheet provides all four for commitment reviews. DatePicker edits require an explicit save; unresolved dates disable Confirm. Dismiss cancels an open candidate. PENDING DEVICE: exercise each action, invalid end times and cancelling an editor.
  3. Confirm updates Today: `resolveReview` sets `.confirmed`, increments version, removes the candidate's review rows and saves on the same main context observed by Today's existing `@Query`. PENDING DEVICE: confirm a tentative item and check Today without relaunching.
  4. Badge: Review tab uses `.badge(reviews.count)` from a live `@Query`. PENDING DEVICE: verify count decreases and disappears at zero on both platforms.
  5. Message-level review: rows show sender and stored evidence's sent time/excerpt when available, otherwise the review's sender, explicitly labelled review creation time and bounded excerpt or reason. Dismiss and Create item are available; creation requires a title, kind and user-selected schedule. Existing source-linked evidence is copied to the new commitment. No message body or new persistence field is introduced. PENDING DEVICE: create and dismiss message-level rows, including one with no excerpt/evidence.
  6. Same-as-existing: picker lists other open items only; store validates the selection again, preserves the existing ID/title/kind/status/provider ID, copies all candidate due fields, transfers its evidence while retaining older evidence, increments the existing version and marks the candidate `.superseded`. PENDING DEVICE: compare IDs, version, due fields and evidence before/after; confirm no duplicate remains in Today.
  7. Every completed action removes its ReviewItem in the same save as the mutation; all reasons attached to a resolved candidate are removed together. Query-backed Today and badge observe that save; failed saves roll back and show an error. PENDING DEVICE: exercise all five actions, persistence after relaunch and failure rollback.
  8. Both targets: new files are under the shared `Recalled` source directory already included by both targets in `project.yml`; UI uses shared SwiftUI/SwiftData APIs. PENDING CI: `app-build` must compile both Recalled and RecalledMac before this criterion can pass.
- Verify commands run and results:
  - `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build`: could not run; PowerShell reported `xcodebuild` is not recognized.
  - `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build`: could not run for the same reason.
  - `Get-Command swift,xcodebuild -ErrorAction SilentlyContinue`: neither tool is installed. Nothing was installed; no Swift tests/builds or device checks are claimed as passed.
  - `git diff --check` and `git diff --no-index --check -- /dev/null` for each new Swift file: passed with no whitespace errors.
  - Static inspection: both targets include the new files; RecalledCore and protected project documents are unchanged. There is no existing app-test target; runtime mutation/rollback verification remains pending the Mac/device gate.
- Not done / risks / questions for the manager: Manager must push `task/T08-review`, obtain green `app-build`, and add the PENDING DEVICE checks above to the Mac gate checklist (I did not edit `docs/PLAN.md`). A message review without linked StoredEvidence has no original source type/sent timestamp; the UI labels its available review time honestly, and Create item does not manufacture evidence/source metadata from a review reason. Extraction wiring and EventKit provider updates remain outside T08.

## Review (round 1)
- Date: 2026-10-23 15:32 AEDT
- Verdict: CHANGES
- Evidence: core-tests run 39900686460 and app-build run 39900686260 green on task/T08-review. Tab badge, Review list, Edit with date-only toggle, Dismiss, Mark as same (existing keeps id, takes due fields and evidence, version bump, candidate superseded) and message-level Create are present; all resolution happens in one save with rollback.

Required fixes:
1. ReviewActions.swift `.confirm`: confirming an item with no date throws "Choose a date and time before confirming". SPEC allows commitments without a date (benchmark fixture ported-04 "Please send the revised proposal. We have not agreed a deadline."). Confirm must accept `dueStart == nil` and set status confirmed; it only validates a schedule when one exists.
2. ReviewActions.swift `.create` and the Create form: `schedule` must be optional ("No date" option in the form), so a message-level review can become a dateless commitment.
3. Extract the decision logic of `resolveReview` (what changes on candidate and existing for each action, which review rows are removed) into a pure function over RecalledCore `Commitment` values, in RecalledCore, with unit tests for: confirm with and without a date, edit, dismiss, merge (id kept, version bumped on both, candidate superseded), create with and without a date, stale or invalid target. `AppStore.resolveReview` then applies the result to the SwiftData rows. This puts the Review rules under core-tests instead of compile-only.

## Dev Report (round 2)
- Date: 2026-10-23 15:37 AEDT
- Changed files: `Recalled/Persistence/ReviewActions.swift`, `Recalled/ReviewQueueView.swift`, `RecalledCore/Sources/RecalledCore/ReviewResolver.swift` (new), `RecalledCore/Tests/RecalledCoreTests/ReviewResolverTests.swift` (new), `tasks/T08-review.md`; `docs/LOG.md` receives the required handoff entry.
- What I did: Addressed all three numbered fixes in Review (round 1). Moved action validation, commitment mutations, evidence transfer instructions and review-row removal selection into the pure `ReviewResolver.resolve` function. It uses Core values and caller-supplied IDs/display text, with no clock, random ID generation or persistence dependency. The main-actor AppStore adapter applies the result to SwiftData and saves once, retaining rollback on failure. Added 16 Swift Testing tests.
- Review fixes (implemented; test execution PENDING CI):
  1. Confirm accepts `dueStart == nil`, confirms the candidate and bumps its version; only an existing schedule is validated. Removed the UI's missing-date block. Covered by `reviewConfirmWithAndWithoutDatePreservesFields` and `reviewConfirmValidatesOnlyAnExistingSchedule`.
  2. Create accepts an optional schedule. The form defaults to an explicit `No date` toggle; turning it off reveals the existing date/time controls. Hidden date values do not block or populate a dateless creation. Covered by `reviewCreateWithAndWithoutDateRemovesOnlySelectedMessageReview`; invalid titles and schedules have separate rejection tests.
  3. Core tests cover confirm with/without a date, edit (including clearing end time), dismiss (candidate, message, orphan and closed candidate), merge, create with/without a date, stale candidates, invalid targets, ID collision and overflow. `reviewMergeKeepsExistingIdentityAndBumpsBothVersions` compares complete expected values, checks both versions and superseding, and asserts evidence reparenting and exact review IDs removed. Action tests verify unrelated/message/merge-target reviews survive. AppStore now executes this decision rather than deciding the transitions itself.
- Acceptance criteria (static inspection only; compilation and tests PENDING CI, runtime checks PENDING DEVICE):
  1. Reasons: existing Review rows continue to display stored reasons, sender/time and evidence summaries; no reason filtering added. PENDING DEVICE for ambiguous date, tentative, mismatch and duplicate examples.
  2. Actions: Confirm, Edit date/time, Dismiss and Mark as same remain available; Confirm now also handles dateless candidates. Core action tests above cover transitions; form interactions PENDING DEVICE.
  3. Confirm/Today: Core confirms and bumps version; the adapter saves on the main context observed by Today. `reviewConfirmWithAndWithoutDatePreservesFields` supplies regression coverage. Live refresh PENDING DEVICE; see the pre-existing dateless agenda limitation below.
  4. Badge: existing `ContentView` query-backed badge observes review deletions. PENDING DEVICE for decrement/zero on both platforms.
  5. Message-level review: existing source summaries and Dismiss remain; Create supports a title, kind and optional user-picked date. `reviewCreateWithAndWithoutDateRemovesOnlySelectedMessageReview`, `reviewDismissMessageOrOrphanRemovesOnlySelectedRow` and `reviewCreateWithoutSourceMetadataDoesNotInventEvidence` cover Core behavior. Adapter preserves stored evidence metadata/context; no message-body persistence introduced. PENDING DEVICE for both dated and dateless creation.
  6. Same-as-existing: full-value merge test verifies existing identity/title/kind/status/actor/provider ID retained, due fields copied (including nil), both versions bumped and candidate superseded. Core emits evidence reparenting; adapter retains older target evidence. PENDING DEVICE for persisted evidence and Today results.
  7. Review removal/refresh: Core returns exact review IDs; tests assert candidate reasons are removed together and unrelated rows preserved. Adapter applies all mutations/deletions in one save with rollback. Live Today/badge updates and save-failure rollback PENDING DEVICE.
  8. Both targets: inspected `project.yml`; Recalled and RecalledMac share the changed app sources and Core package. Both target builds PENDING CI; no compile success is claimed for round 2.
- Verify commands run and results:
  - `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build`: could not run; PowerShell reported `xcodebuild` is not recognized.
  - `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build`: could not run; same missing tool.
  - `swift test --package-path RecalledCore`: could not run; PowerShell reported `swift` is not recognized.
  - `Get-Command swift,xcodebuild -ErrorAction SilentlyContinue`: neither tool available; nothing installed.
  - `git diff --check`: passed. `git diff --no-index --check -- /dev/null` for both new Swift files emitted no whitespace errors (exit 1 indicates files differ from the empty input).
  - Static inspection: resolver imports only Foundation; UI call sites use the Core action/schedule types; app adapter remains main-actor synchronous with a single save/rollback; both workflows already include the needed build/test gates.
- Not done / risks / questions for the manager: Obtain green `core-tests` and `app-build` on `task/T08-review`; round 1's green runs do not validate these changes. All runtime checks remain PENDING DEVICE. Existing `TodayView.items(on:)` excludes `dueStart == nil`, so dateless items now confirm/create successfully and leave Review but are not displayed in Today/Tomorrow agenda sections. This pre-existing Today presentation behavior is outside the three requested fixes and was not changed. No protected documents or EventKit writes were changed.
