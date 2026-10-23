# T07b: "No date" section on Today

| Field | Value |
|---|---|
| Status | in_progress |
| Milestone | M2 |
| Window | Fri 23 Oct (Windows mode) |
| Depends on | T07, T08 |
| Assignee | codex |
| Branch | task/T07b-no-date-section |

## Goal
A confirmed commitment without a date (for example "Please send the revised proposal. We have not agreed a deadline.") is currently invisible: Today only shows items dated today or tomorrow. Show these items too.

## Read
AGENTS.md; docs/SPEC.md: SPEC 5 step 3, 7.3; `Recalled/ContentView.swift`, `Recalled/CommitmentDetailView.swift`

## Acceptance criteria
- [x] Today has a third section "No date", below "Today" and "Tomorrow", listing commitments with status `confirmed` and no `dueStart`
- [x] Rows look like the other agenda rows (source icon, title, actor) and open the same Detail view
- [x] Sorted by title (case insensitive), so the order is stable
- [x] The section is hidden when empty; tentative, needsReview, completed, cancelled and superseded items never appear in it
- [x] The filter is a pure function over RecalledCore `Commitment` values (`[Commitment] -> [Commitment]`) in RecalledCore with unit tests for the status and date rules and the ordering, so it is covered by core-tests
- [x] Seed data includes one confirmed item without a date, so the section shows after "Reset demo"
- [x] Builds on both `Recalled` and `RecalledMac`

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `app-build` (and `core-tests`) must be green on `task/T07b-no-date-section`. Criteria that need a running app are reviewed as compile-checked and marked PENDING DEVICE; the manager adds them to the "Mac gate checklist" in docs/PLAN.md.

## Verify
```
swift test --package-path RecalledCore
xcodegen && xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' build
```

## Out of scope
Items dated after tomorrow (a later "Upcoming" view), editing from Today.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->

## Dev Report (round 1)
- Date: 2026-10-23 16:45 AEDT
- Changed files: `Recalled/ContentView.swift`, `Recalled/Persistence/Seed.swift`, `RecalledCore/Sources/RecalledCore/AgendaFilter.swift`, `RecalledCore/Tests/RecalledCoreTests/AgendaFilterTests.swift`, `tasks/T07b-no-date-section.md`; completion entry in `docs/LOG.md`.
- What I did: Added `AgendaFilter.noDate`, a pure `[Commitment] -> [Commitment]` filter with case-insensitive title sorting and UUID tie-breaking. Today maps its results back to stored commitments and shows a nonempty No date section after Tomorrow. All three agenda sections share the same row and Detail destination; rows explicitly show the actor as well as the existing evidence/source label. Added a confirmed, undated proposal seed and preserved its status by skipping date resolution for empty date text. Nonempty seed dates still use DateResolver.
- Acceptance criteria:
  1. Third No date section below Today/Tomorrow, containing only confirmed items without dueStart: implemented in TodayView using AgendaFilter.noDate; `noDateIncludesOnlyConfirmedStatus` and `noDateExcludesEveryStartDateButDoesNotRequireAnEmptyEndOrDateText` cover the rules. PENDING CI compile check and PENDING DEVICE appearance check.
  2. Same agenda row appearance (source icon, title, actor) and same Detail view: all sections call `agendaRow`, which links to CommitmentDetailView with the stored item. PENDING CI compile check and PENDING DEVICE navigation/appearance check.
  3. Stable case-insensitive title ordering: covered by `noDateSortsTitlesIgnoringCase` and `noDateTitleTiesUseIdentityRegardlessOfInputOrder`, including identical-title ties. Tests written, execution pending core-tests.
  4. Hidden when empty and excludes tentative, needsReview, completed, cancelled and superseded: guarded by `!undated.isEmpty`; the allCases status test also excludes candidate. `noDateHandlesEmptyInputAndNoEligibleItems` covers empty results. PENDING DEVICE empty-section check; core-tests pending.
  5. Pure RecalledCore filter and unit tests: AgendaFilter imports only Foundation and operates solely on input Commitment values; five Swift Testing tests added to the existing RecalledCoreTests target. Execution pending core-tests.
  6. Reset demo includes an undated confirmed item: `Send revised proposal`, with source evidence and empty due text, retains the seed's default confirmed status and nil dueStart. PENDING DEVICE Reset demo check.
  7. Builds on Recalled and RecalledMac: implementation uses their existing shared source directory and platform-neutral SwiftUI/Core APIs. NOT VERIFIED locally; both builds await app-build CI on task/T07b-no-date-section.
- Verify commands run and results:
  - `swift test --package-path RecalledCore`: attempted; could not run because swift is not installed/recognized.
  - `xcodegen && xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build`: attempted with PowerShell's conditional-success equivalent; xcodegen is not installed/recognized, so the dependent build did not run.
  - `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' build`: attempted; could not run because xcodebuild is not installed/recognized.
  - `git diff --check`: passed, no whitespace errors. Source/diff review completed; this is not a compile or runtime check.
- Not done / risks / questions for the manager: Windows has no Swift toolchain or Xcode; no tools were installed and no tests/builds are claimed to pass. Manager must push and obtain green core-tests and app-build, then add the PENDING DEVICE checks to the Mac gate checklist. Existing Detail view displays Date = Needs review for any nil dueStart, including confirmed undated items; noted without changing it outside this task's Today scope. No other task started; no merge or push performed.

## Review (round 1)
- Date: 2026-10-23 16:49 AEDT
- Verdict: PASS
- Evidence: core-tests run 39907633419 green (new AgendaFilterTests), app-build run 39907633400 green on task/T07b-no-date-section.
- Checked: AgendaFilter.noDate is a pure RecalledCore function (confirmed and no dueStart, title order ignoring case, id breaks ties); Today shows "No date" below Today and Tomorrow, hidden when empty, rows reuse the shared agendaRow (now with actor) and open Detail; seed adds "Send revised proposal" with no date, and an empty due is no longer treated as ambiguous.
- PENDING DEVICE: moved to the Mac gate checklist (T07b row).
