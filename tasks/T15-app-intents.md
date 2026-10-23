# T15: App Intents for Siri and Shortcuts

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M5 |
| Window | Sun 25 Oct, 10:30 to 12:00 |
| Depends on | T07 |
| Assignee | codex |
| Branch | task/T15-app-intents |

## Goal
'What did I promise Adit?' works from Siri.

## Read
AGENTS.md; docs/SPEC.md: SPEC 6 S1

## Acceptance criteria
- [ ] Intents: WhatsOnIntent(date), WhatDidIPromiseIntent(person), each returning a spoken dialog and a snippet view
- [ ] AppShortcutsProvider with natural phrases
- [ ] Reads only from the local store

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Writes via Siri.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
