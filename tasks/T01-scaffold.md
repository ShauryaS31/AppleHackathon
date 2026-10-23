# T01: Repo scaffold: XcodeGen project, Core package, Share extension, CI

| Field | Value |
|---|---|
| Status | in_progress |
| Milestone | M0 |
| Window | Fri 23 Oct, 18:30 to 21:00 |
| Depends on | T00 |
| Assignee | codex |
| Branch | task/T01-scaffold |

## Goal
Create a buildable skeleton so every later task only adds code.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7.1, 7.6

## Acceptance criteria
- [ ] `project.yml` (XcodeGen) defines targets Recalled (iOS 26 app) and RecalledShare (share extension), App Group `group.au.recalled.app`, and a local package dependency on RecalledCore. No hand-edited .pbxproj committed; `Recalled.xcodeproj` is gitignored and generated
- [ ] `RecalledCore/` Swift package (swift-tools-version 6.0) with one placeholder type and one passing test
- [ ] SCXSwiftKit added as an SPM dependency of the app target from github.com/SouthernCrossAI/SCXSwiftKit (pin the latest tag)
- [ ] `Secrets.xcconfig.example` with `SCX_API_KEY` and `ELEVENLABS_API_KEY`; real `Secrets.xcconfig` gitignored; keys exposed via Info.plist build settings
- [ ] App launches to a placeholder screen showing whether `SystemLanguageModel.default.availability` is available
- [ ] `.github/workflows/core-tests.yml` runs `swift test --package-path RecalledCore` on a GitHub macOS runner on push and PR
- [ ] `.gitignore` covers Xcode, DerivedData, xcuserdata, Secrets.xcconfig, .DS_Store
- [ ] README section: how to generate the project (`brew install xcodegen && xcodegen`) and run

### Added by manager (2026-10-23, Windows mode and Mac fallback)
- [ ] `project.yml` also defines `RecalledMac`: a native macOS 26 app target (not Catalyst) that compiles the same `Recalled/` sources, depends on RecalledCore and SCXSwiftKit, and does not embed RecalledShare. iOS-only code is wrapped in `#if os(iOS)`. Same placeholder screen works on both
- [ ] Both app targets read build settings from `Config/App.xcconfig`, which does `#include? "../Secrets.xcconfig"` (optional include) so the project generates and builds when the secrets file is missing (CI, fresh clones)
- [ ] `RecalledCore/Package.swift`: swift-tools-version 6.0, platforms `.iOS(.v18), .macOS(.v15)` so `swift test` runs on any current GitHub macOS runner
- [ ] `.github/workflows/core-tests.yml`: triggers on push to any branch and on pull_request; `runs-on: macos-26`; prints `xcodebuild -version` and `swift --version`; runs `swift test --package-path RecalledCore`
- [ ] `.github/workflows/app-build.yml`: same triggers and runner; `brew install xcodegen`; `xcodegen`; then two builds with `CODE_SIGNING_ALLOWED=NO`: `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build` and `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' build`
- [ ] `project.yml` generates shared schemes named `Recalled` and `RecalledMac`

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` and `app-build` must both be green on `task/T01-scaffold`.

## Verify
```
swift test --package-path RecalledCore
xcodegen && xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' build
```
In Windows mode: the GitHub Actions runs on the task branch.

## Out of scope
Any feature logic.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
