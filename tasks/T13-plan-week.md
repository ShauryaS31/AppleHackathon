# T13: Plan my week via SCX MAGPiE

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M4 |
| Window | Sat 24 Oct, 19:00 to 20:00 |
| Depends on | T06, T12 |
| Assignee | codex |
| Branch | task/T13-plan-week |

## Goal
Long-context planning with minimised data.

## Read
AGENTS.md; docs/SPEC.md: SPEC 5 step 5; 7.5 item 6

## Acceptance criteria
- [ ] 'Plan my week' builds a structured payload of the next 7 days of commitments and calendar events (titles, times, kinds, statuses, conflicts), pseudonymised
- [ ] Region check, then call SCXPlanningModel; stream the answer
- [ ] Answer rehydrated on device before display
- [ ] LedgerEntry written for every request, including refused ones
- [ ] Planner output is text only; it cannot trigger actions

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Agentic actions from the plan.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
