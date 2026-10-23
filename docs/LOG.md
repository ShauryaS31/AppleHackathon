# Log (append only)

Format: `- YYYY-MM-DD HH:MM AEDT | Task | actor | event | detail`
Events: dispatch, dev-report rN, review rN PASS/CHANGES, merge, blocked, gate PASS/FAIL, decision.

## Friday 23 October 2026
- 2026-10-23 13:00 AEDT | - | claude (cowork) | decision | Spec, plan, factory protocol and 19 task briefs created
- 2026-10-23 13:26 AEDT | T00 | claude (cowork) | setup | Files placed in repo folder; ElevenLabs key copied from Recalled .env.local into gitignored Secrets.xcconfig; SCX key still missing
- 2026-10-23 13:27 AEDT | T00 | claude | dispatch | codex exec --help checked (codex-cli 0.163.0): --model, --sandbox workspace-write, -C all valid, CLAUDE.md command unchanged; dummy round trip dispatched on task/T00-factory-check
- 2026-10-23 13:28 AEDT | T00 | codex | dev-report r1 | Dummy round trip: developer process can read the repo, write a file and commit
- 2026-10-23 13:30 AEDT | T00 | claude | review r1 PASS | Manager items done: codex flags valid, dummy round trip committed b588bd4; owner items open
- 2026-10-23 13:31 AEDT | T00 | claude | merge | task/T00-factory-check merged to main (--no-ff); T00 set blocked pending owner items (Xcode, device, signing, keys, organiser confirmation)
- 2026-10-23 13:29 AEDT | - | claude (cowork) | decision | Codex output streamed to logs/current.log for live viewing; interactive tmux mode and manual relay documented in FACTORY.md
- 2026-10-23 13:45 AEDT | - | claude | decision | Owner: zero budget, native Swift, repo public, Windows mode T01>T02>T03>T04>T12 gated by GitHub Actions core-tests (plus app-build for app code), RecalledMac fallback target; stop after T12. Briefs T01 to T04 and T12 tightened for Windows mode
- 2026-10-23 13:47 AEDT | T01 | claude | dispatch | round 1 on task/T01-scaffold (Windows mode, gate: core-tests + app-build CI)
- 2026-10-23 13:48 AEDT | T01 | codex | dev-report r1 | iOS/macOS scaffold, Core placeholder and CI written; static checks passed, Apple toolchain checks pending; commit blocked by read-only .git sandbox
- 2026-10-23 14:05 AEDT | T01 | claude | review r1 PASS | core-tests and app-build green on macos-26 (Xcode 26.6); launch check left for owner at M0 gate
- 2026-10-23 14:06 AEDT | T01 | claude | merge | task/T01-scaffold merged to main, status done; CLAUDE.md dispatch updated: manager commits for Codex (sandbox .git is read-only)
- 2026-10-23 13:52 AEDT | T02 | claude | dispatch | round 1 on task/T02-core-models (gate: core-tests CI)
- 2026-10-23 13:55 AEDT | T02 | codex | dev-report r1 | Core models, Sendable protocols, fakes and 17 tests committed as 577b97f; static checks passed, Swift unavailable on Windows, core-tests CI pending
- 2026-10-23 13:58 AEDT | - | claude | correction | Timestamps on the T01 review r1 and merge lines (14:05, 14:06) were estimated, not read from the clock; actual times were about 13:50 and 13:51
- 2026-10-23 13:58 AEDT | T02 | claude | review r1 CHANGES | CI green; 6 fixes: message-level ReviewItem, rename .none cases, lenient SourceMessage decode, PlanItem without UUIDs, throwing fakes, deterministic fake ids
- 2026-10-23 14:01 AEDT | T02 | codex | dev-report r2 | Addressed all six review fixes with regression tests; committed e06ba7d; static checks passed, Swift unavailable on Windows, core-tests CI pending
- 2026-10-23 14:03 AEDT | T02 | claude | review r2 PASS | 24 tests green on core-tests 39892767862; app-build green
- 2026-10-23 14:03 AEDT | T02 | claude | merge | task/T02-core-models merged to main, status done
- 2026-10-23 14:03 AEDT | T03 | claude | dispatch | round 1 on task/T03-prefilter (gate: core-tests CI)
- 2026-10-23 14:06 AEDT | T03 | codex | dev-report r1 | Normaliser, quote/signature stripper, rules prefilter and 38 tests written; Swift unavailable, core-tests CI pending; commit blocked by sandbox index.lock permission denial, manager commits
- 2026-10-23 14:10 AEDT | T03 | claude | review r1 PASS | 38 tests green on core-tests 39893355458; app-build green
- 2026-10-23 14:10 AEDT | T03 | claude | merge | task/T03-prefilter merged to main, status done
- 2026-10-23 14:10 AEDT | T04 | claude | dispatch | round 1 on task/T04-resolvers (gate: core-tests CI)
- 2026-10-23 14:17 AEDT | T04 | codex | dev-report r1 | Deterministic date/evidence/match/conflict resolvers and commitment updates committed with 30 tests; Swift unavailable on Windows, core-tests CI pending
- 2026-10-23 14:20 AEDT | T04 | claude | review r1 PASS | 92 tests green on core-tests 39894209979; app-build green; DateResolver phrasing coverage noted for T16
- 2026-10-23 14:20 AEDT | T04 | claude | merge | task/T04-resolvers merged to main, status done
- 2026-10-23 14:20 AEDT | T12 | claude | dispatch | round 1 on task/T12-pseudonymiser (gate: core-tests and app-build CI)
- 2026-10-23 14:25 AEDT | T12 | codex | dev-report r1 | Added local pseudonymiser, 10 test functions with 10 privacy fixtures, and shared ledger screen; committed beb7a1c; Swift/Xcode unavailable on Windows, core-tests and app-build CI pending
- 2026-10-23 14:28 AEDT | T12 | claude | review r1 PASS | core-tests 39894985789 and app-build 39894985815 green
- 2026-10-23 14:28 AEDT | T12 | claude | merge | task/T12-pseudonymiser merged to main, status done. Windows-mode run complete (T01 to T04, T12); stopping for owner as instructed
- 2026-10-23 14:51 AEDT | - | claude | decision | Owner: drop OCR (T09 now share and paste, text only; SPEC 5, 6 M1, 7, 7.1, 7.7, A1 and M2 gate updated), new T04b, T05 split into T05a and T05b (blocked on device), Windows mode continues T04b, T05a, T07, T08, T09, T10; Mac gate checklist added to PLAN. Briefs tightened; old extraction rules and fixtures copied to docs/notes
- 2026-10-23 14:51 AEDT | T04b | claude | dispatch | round 1 on task/T04b-date-phrases (gate: core-tests CI)
- 2026-10-23 14:55 AEDT | T04b | codex | dev-report r1 | Common date phrases and 10 new test functions committed as 6870bff; existing tests unchanged; Swift unavailable on Windows, core-tests CI pending
- 2026-10-23 14:58 AEDT | T04b | claude | review r1 PASS | 112 tests green on core-tests 39897652689; app-build green
- 2026-10-23 14:58 AEDT | T04b | claude | merge | task/T04b-date-phrases merged to main, status done
- 2026-10-23 14:59 AEDT | T05a | claude | dispatch | round 1 on task/T05a-instructions-benchmark (gate: core-tests and app-build CI)
- 2026-10-23 15:04 AEDT | T05a | codex | dev-report r1 | Added extraction instructions, 20 benchmark fixtures and five Core tests; committed ed8b639; Swift/Xcode unavailable on Windows, core-tests and app-build CI pending
- 2026-10-23 15:07 AEDT | T05a | claude | review r1 PASS | 117 tests green on core-tests 39898373541; app-build 39898373522 green (both apps bundle benchmark.json)
