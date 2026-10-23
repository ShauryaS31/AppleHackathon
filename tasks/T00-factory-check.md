# T00: Factory smoke test and accounts

| Field | Value |
|---|---|
| Status | in_progress |
| Milestone | M0 |
| Window | Fri 23 Oct, 13:00 to 18:00 |
| Depends on | - |
| Assignee | owner + manager |
| Branch | task/T00-factory-check |

## Goal
Prove the factory loop works end to end and that every account and device we depend on is ready.

## Read
AGENTS.md; docs/SPEC.md: FACTORY.md; SPEC 7.6, 9

## Acceptance criteria
- [ ] Owner: Mac with Xcode 26 available for the event; `xcodebuild -version` recorded in LOG
- [ ] Owner: iPhone 15 Pro or later (or Apple silicon Mac) with Apple Intelligence enabled; recorded in LOG
- [ ] Owner: Apple developer account can sign to the device
- [ ] Owner: SCX API key and ElevenLabs API key obtained (not committed)
- [ ] Owner: confirm with organisers that disclosed prior work is acceptable
- [ ] Manager: `codex exec --help` checked; dispatch command in CLAUDE.md corrected if needed
- [ ] Manager: dummy dispatch round trip done (Codex adds a line to docs/LOG.md on a branch, manager reviews and merges)

## Verify
```
git log --oneline -3
```

## Out of scope
Any app code.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
