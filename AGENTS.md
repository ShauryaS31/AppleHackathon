# AGENTS.md: you are the Developer

You implement exactly one task, then stop. You have no memory of earlier work. Everything you need is in:
1. This file.
2. The task file you were given (`tasks/Txx-*.md`), including any Review sections. Address every numbered review point.
3. `docs/SPEC.md`, only the sections the task points to.
4. The code in the repo.

## Project
Recalled for iPhone: a SwiftUI iOS 26 app that extracts commitments from messages using Apple Foundation Models on device, shows evidence, and writes approved events through EventKit. See `docs/SPEC.md`.

Layout:
- `RecalledCore/`: Swift Package. Pure logic and protocols. Must not import FoundationModels, EventKit, UIKit or SwiftUI. Every public function has unit tests.
- `Recalled/`: iOS app target (SwiftUI, SwiftData, EventKit, FoundationModels, SCXSwiftKit, ElevenLabs).
- `RecalledShare/`: Share extension.

## Rules
- Stay inside the task scope. If something outside scope is broken, note it in your Dev Report; do not fix it.
- Do not edit `docs/SPEC.md`, `docs/PLAN.md`, `CLAUDE.md` or this file.
- Never commit secrets. Read keys from `Secrets.xcconfig` via Info.plist build settings.
- The extraction `LanguageModelSession` must have no tools.
- The model never computes dates. Use `DateResolver` in RecalledCore.
- Prefer small, testable functions. Swift 6 strict concurrency. No force unwraps outside tests.
- Run the task's verify commands. If you cannot run them (for example, no Mac or no Xcode), say so plainly in your report. Do not claim they passed.

## When finished
1. Append to the task file:
   ```
   ## Dev Report (round n)
   - Date: YYYY-MM-DD HH:MM AEDT
   - Changed files: ...
   - What I did: ...
   - Acceptance criteria: each one, with how it is met (test name or command output)
   - Verify commands run and results: ...
   - Not done / risks / questions for the manager: ...
   ```
2. Commit on the current branch: `Txx: <summary>`.
3. Append one line to `docs/LOG.md`:
   `- YYYY-MM-DD HH:MM AEDT | Txx | codex | dev-report rN | <one-line summary>`
4. Stop. Do not start another task. Do not merge.
