# T06: SCXSwiftKit spike: PlanningModel implementation

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M1 |
| Window | Sat 24 Oct, 10:00 to 11:30 (parallel worktree) |
| Depends on | T01 |
| Assignee | codex |
| Branch | task/T06-scx-spike |

## Goal
De-risk the SCX integration early.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.5 item 6; 7.6

## Acceptance criteria
- [ ] Read SCXSwiftKit README and source; summarise the real API (model listing, regions, session creation, reasoning level) in `docs/notes/scx.md`
- [ ] `SCXPlanningModel: PlanningModel` selects MAGPiE, exposes its region codes, reasoning level Moderate
- [ ] A debug button sends a fixed harmless prompt and shows the streamed reply
- [ ] Refuses to send if regions do not contain AU, with a visible error

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Pseudonymisation, UI beyond the debug button.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
