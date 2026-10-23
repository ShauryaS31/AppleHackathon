# T18: STRETCH: Create ML triage classifier

| Field | Value |
|---|---|
| Status | todo |
| Milestone | Stretch |
| Window | Only if ahead of plan |
| Depends on | T05b |
| Assignee | owner + codex |
| Branch | task/T18-coreml-triage |

## Goal
Distil the old cloud Decisions classifier into an on-device model.

## Read
AGENTS.md; docs/SPEC.md: Architecture doc, Tier 1 option B

## Acceptance criteria
- [ ] Export labelled examples from the old Supabase project (owner)
- [ ] Train a Create ML text classifier, add the .mlmodel, use it in Prefilter before the FM call
- [ ] Report precision and recall on a held-out set with real counts

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Shipping personal email in the repo: training data stays local.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
