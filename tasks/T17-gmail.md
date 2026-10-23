# T17: STRETCH: Gmail fetch from device

| Field | Value |
|---|---|
| Status | todo |
| Milestone | Stretch |
| Window | Only if M3 passes by 17:00 Sat |
| Depends on | T10 |
| Assignee | codex |
| Branch | task/T17-gmail |

## Goal
Live email source without a server.

## Read
AGENTS.md; docs/SPEC.md: SPEC 6 S2; 7.5 item 1

## Acceptance criteria
- [ ] Google Sign-In for iOS, gmail.readonly scope, token in Keychain
- [ ] Fetch last 14 days, newest first, through prefilter and extractor, results appear progressively
- [ ] Connection status and last sync shown

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Sending email.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
