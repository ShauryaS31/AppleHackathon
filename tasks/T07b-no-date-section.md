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
- [ ] Today has a third section "No date", below "Today" and "Tomorrow", listing commitments with status `confirmed` and no `dueStart`
- [ ] Rows look like the other agenda rows (source icon, title, actor) and open the same Detail view
- [ ] Sorted by title (case insensitive), so the order is stable
- [ ] The section is hidden when empty; tentative, needsReview, completed, cancelled and superseded items never appear in it
- [ ] The filter is a pure function over RecalledCore `Commitment` values (`[Commitment] -> [Commitment]`) in RecalledCore with unit tests for the status and date rules and the ordering, so it is covered by core-tests
- [ ] Seed data includes one confirmed item without a date, so the section shows after "Reset demo"
- [ ] Builds on both `Recalled` and `RecalledMac`

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
