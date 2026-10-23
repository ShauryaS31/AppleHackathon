# The Software Factory: how agents work in this repo

Claude Code is the **manager and reviewer**. Codex (gpt-6-astra) is the **developer**. Shaurya is the **owner**: approves milestones, tests on the real device, holds the keys.

All state lives in files, so any agent can be restarted with zero memory and pick up where things stopped.

## Files

| File | Who writes | Purpose |
|---|---|---|
| `docs/SPEC.md` | Owner, Manager (with approval) | What we are building. Source of truth |
| `docs/PLAN.md` | Manager | Dated milestones and the task board (status table) |
| `docs/LOG.md` | Everyone, append only | Dated, timestamped record of every dispatch, report, review, merge |
| `tasks/Txx-*.md` | Manager writes the brief and reviews; Developer writes Dev Reports | One file per task. The full brief. Developer needs nothing else |
| `CLAUDE.md` | Owner | Manager instructions (Claude Code reads it automatically) |
| `AGENTS.md` | Owner | Developer instructions (Codex reads it automatically) |

Why one file per task and not one big shared doc: two agents editing the same file causes overwrites and merge conflicts, and every agent would load the whole history into context. A task file holds only what that task needs.

## Statuses

`todo` > `in_progress` > `in_review` > `changes_requested` (loops back to `in_progress`) > `done`
Also `blocked` (needs owner) and `dropped`.

## The loop

```
Manager                                     Developer (fresh process each time)
-------                                     ----------------------------------
1. Pick next task: first `todo` in PLAN.md
   whose dependencies are all `done`
2. Check the brief is complete. Set
   `in_progress`. Create branch
   task/Txx-slug from main. LOG entry.
3. Dispatch:  codex exec ... "Do task Txx"  -->  Reads AGENTS.md + tasks/Txx.md only
                                                Implements on the branch
                                                Runs the task's verify commands
                                                Appends "Dev Report (round n)"
                                                Commits, appends LOG line, exits
4. Review (in a review subagent if the diff
   is large, to keep the manager's context
   small):
   - git diff main...task/Txx
   - run verify commands yourself
   - check every acceptance criterion
   - check SPEC rules (no tools in reader,
     no secrets, Core has no platform imports)
   Write "Review (round n)" with verdict.
5a. PASS: merge to main (no fast-forward),
    status `done`, LOG entry, go to 1.
5b. CHANGES: list exact numbered fixes,
    status `changes_requested`, go to 3
    (new Developer process, same branch).
5c. Round 3 still failing, or needs device,
    keys, accounts or a product decision:
    status `blocked`, notify owner, move
    on to another task.
6. End of milestone: STOP and ask owner for
   the milestone gate (device test).
```

## Context hygiene

- The Developer never sees the chat. If it is not in the task file, AGENTS.md or the repo, it does not exist.
- One `codex exec` process per round. It exits when done, so its context is thrown away.
- The manager keeps only the board in its head. For a fresh start: read `docs/PLAN.md` and the last 30 lines of `docs/LOG.md`. Use `/clear` (or a new Claude Code session) after each milestone.
- The manager reviews big diffs through a subagent and keeps only the verdict.

## Gates

A task can only pass if all of these hold:
1. `swift test --package-path RecalledCore` passes (on Mac or the CI macOS runner).
2. The app builds: `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build` (on Mac).
3. Every acceptance criterion in the task is checked with evidence (test name, command output or screenshot path).
4. No secrets in the diff. `Secrets.xcconfig` stays gitignored.

Things agents cannot verify and must hand to the owner: anything on the physical iPhone, Apple Intelligence output quality, OAuth consent screens, audio playback, signing and provisioning.

## Parallel work (optional)

Run at most 2 developers at once, only on tasks with no shared files, each in its own git worktree:
`git worktree add ../ah-Txx task/Txx-slug`, then dispatch with `-C ../ah-Txx`.

## Platform warning

iOS apps only build on a Mac with Xcode 26. If the manager and developer run on Windows, they can write code but cannot build it. Then the only gate is CI (`RecalledCore` tests on a GitHub macOS runner), and the app target is unverified until it is opened on a Mac. Run the factory on the Mac during the event.
