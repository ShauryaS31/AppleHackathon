# T16: Demo hardening

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M6 |
| Window | Sun 25 Oct, 12:00 to 13:00 (code freeze 13:00) |
| Depends on | T09, T11, T13, T14 |
| Assignee | codex + owner |
| Branch | task/T16-demo-hardening |

## Goal
Nothing breaks on stage.

## Read
AGENTS.md; docs/SPEC.md: SPEC 5

## Acceptance criteria
- [ ] 'Reset demo' puts the app in the exact starting state of the demo script
- [ ] Benchmark numbers from T05 shown on an 'About this build' screen with the prior-work disclosure
- [ ] Every network step has a visible timeout and a graceful message
- [ ] Owner: full 5-minute run on device twice, timings recorded in LOG; fallback video recorded

### Manager note (2026-10-23, from T04 review)
- [ ] DateResolver also resolves: leading 'by', 'on', 'this'; weekday plus date ('Sat 25 Oct'); a comma between date and time; 'tonight' (19:00) and 'noon' (12:00). Each with a Sydney-time-zone unit test. Only if demo messages use these forms.

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
New features.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
