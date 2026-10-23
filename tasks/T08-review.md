# T08: Review queue

| Field | Value |
|---|---|
| Status | in_progress |
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
