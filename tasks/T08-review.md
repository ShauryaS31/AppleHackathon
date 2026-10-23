# T08: Review queue

| Field | Value |
|---|---|
| Status | todo |
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
