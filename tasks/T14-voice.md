# T14: ElevenLabs morning briefing

| Field | Value |
|---|---|
| Status | todo |
| Milestone | M5 |
| Window | Sun 25 Oct, 10:00 to 11:00 |
| Depends on | T07 |
| Assignee | codex, then owner on device |
| Branch | task/T14-voice |

## Goal
Voice that reads the verified plan.

## Read
AGENTS.md; docs/SPEC.md: SPEC 5 step 6; 6 M7

## Acceptance criteria
- [ ] Briefing text generated on device (Foundation Models, no tools) from today's confirmed items, conflicts and open Review count
- [ ] ElevenLabs TTS via REST, played with AVAudioPlayer; AVSpeechSynthesizer fallback if offline or key missing
- [ ] Only the briefing text is sent to ElevenLabs; logged in the ledger
- [ ] Owner gate: audible on device

## Verify
```
xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Conversational agent.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
