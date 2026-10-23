# T09: Share extension with Vision OCR

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M2 |
| Window | Sat 24 Oct, 14:00 to 15:30 |
| Depends on | T07 |
| Assignee | codex, then owner on device |
| Branch | task/T09-share-ocr |

## Goal
Get WhatsApp, Messages and screenshots in.

## Read
AGENTS.md; docs/SPEC.md: SPEC 6 M1; 5 step 2

## Acceptance criteria
- [ ] RecalledShare accepts text, URLs and images
- [ ] Images run through Vision VNRecognizeTextRequest (accurate, en-AU), text joined in reading order
- [ ] Extension writes a SourceMessage JSON to the App Group inbox and shows a short 'Sent to Recalled' confirmation; it does not run the language model (memory limits)
- [ ] Main app processes the inbox on launch and on foreground, through prefilter and extractor
- [ ] Owner gate: share a real WhatsApp screenshot in airplane mode and see the item in Review with evidence (A1, A10)

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Gmail.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
