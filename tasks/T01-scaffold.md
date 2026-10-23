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
- [x] `project.yml` (XcodeGen) defines targets Recalled (iOS 26 app) and RecalledShare (share extension), App Group `group.au.recalled.app`, and a local package dependency on RecalledCore. No hand-edited .pbxproj committed; `Recalled.xcodeproj` is gitignored and generated
- [x] `RecalledCore/` Swift package (swift-tools-version 6.0) with one placeholder type and one passing test
- [x] SCXSwiftKit added as an SPM dependency of the app target from github.com/SouthernCrossAI/SCXSwiftKit (pin the latest tag)
- [x] `Secrets.xcconfig.example` with `SCX_API_KEY` and `ELEVENLABS_API_KEY`; real `Secrets.xcconfig` gitignored; keys exposed via Info.plist build settings
- [ ] App launches to a placeholder screen showing whether `SystemLanguageModel.default.availability` is available
- [x] `.github/workflows/core-tests.yml` runs `swift test --package-path RecalledCore` on a GitHub macOS runner on push and PR
- [x] `.gitignore` covers Xcode, DerivedData, xcuserdata, Secrets.xcconfig, .DS_Store
- [x] README section: how to generate the project (`brew install xcodegen && xcodegen`) and run

### Added by manager (2026-10-23, Windows mode and Mac fallback)
- [x] `project.yml` also defines `RecalledMac`: a native macOS 26 app target (not Catalyst) that compiles the same `Recalled/` sources, depends on RecalledCore and SCXSwiftKit, and does not embed RecalledShare. iOS-only code is wrapped in `#if os(iOS)`. Same placeholder screen works on both
- [x] Both app targets read build settings from `Config/App.xcconfig`, which does `#include? "../Secrets.xcconfig"` (optional include) so the project generates and builds when the secrets file is missing (CI, fresh clones)
- [x] `RecalledCore/Package.swift`: swift-tools-version 6.0, platforms `.iOS(.v18), .macOS(.v15)` so `swift test` runs on any current GitHub macOS runner
- [x] `.github/workflows/core-tests.yml`: triggers on push to any branch and on pull_request; `runs-on: macos-26`; prints `xcodebuild -version` and `swift --version`; runs `swift test --package-path RecalledCore`
- [x] `.github/workflows/app-build.yml`: same triggers and runner; `brew install xcodegen`; `xcodegen`; then two builds with `CODE_SIGNING_ALLOWED=NO`: `xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build` and `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' build`
- [x] `project.yml` generates shared schemes named `Recalled` and `RecalledMac`

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

## Dev Report (round 1)
- Date: 2026-10-23 13:48 AEDT
- Changed files: `project.yml`; `Config/App.xcconfig`; `Recalled/RecalledApp.swift`; `Recalled/ContentView.swift`; `RecalledShare/ShareViewController.swift`; `RecalledCore/Package.swift`; `RecalledCore/Sources/RecalledCore/RecalledPlaceholder.swift`; `RecalledCore/Tests/RecalledCoreTests/RecalledPlaceholderTests.swift`; `.github/workflows/core-tests.yml`; `.github/workflows/app-build.yml`; `.gitignore`; `README.md`; `tasks/T01-scaffold.md`. `docs/LOG.md` is appended after the commit, as instructed.
- What I did: Added the iOS and native macOS scaffold, dismissible share-extension placeholder, pure Core package, exact SCX package pin, optional secrets configuration, generated plist/entitlement definitions, shared schemes, and CI. No feature logic or extraction sessions were added. Read only SPEC 7.1 and 7.6. There were no Review sections to address.
- Acceptance criteria (in task order; runtime/build claims remain pending CI):
  1. `project.yml` defines the iOS 26 app and share extension, embeds the extension in the iOS app, assigns `group.au.recalled.app`, and links the local RecalledCore package. Static configuration assertions passed. `git check-ignore` confirms the generated Xcode project is ignored; `git ls-files '*.pbxproj'` returned no files.
  2. Core uses tools 6.0 and contains one placeholder type and one test, `placeholderProvidesAppName`. Test execution is pending; no passing Swift test is claimed locally.
  3. Both apps depend on SCXSwiftKit with `exactVersion: "1.0.0"`. The connected GitHub API returned `1.0.0` as the sole tag at `https://api.github.com/repos/SouthernCrossAI/SCXSwiftKit/git/refs/tags`; the tagged manifest confirms the `SCXSwiftKit` library product and iOS/macOS 26 support.
  4. The existing `Secrets.xcconfig.example` already has both required key names and was retained. Both app Info.plist definitions substitute `$(SCX_API_KEY)` and `$(ELEVENLABS_API_KEY)`. `git check-ignore Secrets.xcconfig` passed; `git ls-files Secrets.xcconfig` returned no files. The real secrets file was not read or modified.
  5. Both app entry points use the same `ContentView`, which reads `SystemLanguageModel.default.availability`, displays available/unavailable/unknown status, and refreshes when the scene becomes active. Launch and UI behavior need Mac/device verification.
  6. `core-tests.yml` runs the exact Core test command on push and pull request. YAML configuration assertions passed; workflow execution is pending the manager's push.
  7. `.gitignore` covers Xcode projects/workspaces, DerivedData, xcuserdata, user state, Swift build output, generated configuration files, Secrets.xcconfig and .DS_Store. Representative ignored paths were checked with `git check-ignore`.
  8. README documents `brew install xcodegen && xcodegen`, opening the generated project, selecting each scheme, running, signing, optional keys, and verification.
  9. `RecalledMac` is a native `macOS` application targeting 26.0, uses the same `Recalled/` sources, links both packages, and has no extension target dependency. Static assertions passed. UIKit code lives only in RecalledShare and is guarded by `#if os(iOS)`; shared app sources require no iOS-only APIs.
  10. Both app targets map Debug and Release to `Config/App.xcconfig`, with empty key defaults followed by the exact optional include `#include? "../Secrets.xcconfig"`. Static assertions passed; building without secrets remains a CI check.
  11. Core's manifest declares tools 6.0 and `.iOS(.v18), .macOS(.v15)`. Static assertions also verified no prohibited framework imports in Core.
  12. `core-tests.yml` has unrestricted push and pull_request triggers, `macos-26`, toolchain version output, and the required test command. YAML assertions passed.
  13. `app-build.yml` has the same triggers/runner, prints toolchain versions, installs XcodeGen, generates the project, and builds both specified destinations with `CODE_SIGNING_ALLOWED=NO`. YAML assertions passed; builds remain pending CI.
  14. `project.yml` explicitly defines shared schemes `Recalled` and `RecalledMac`. Static assertions passed; generated schemes need XcodeGen validation on the Mac runner.
- Verify commands run and results: `Get-Command swift,xcodegen,xcodebuild -ErrorAction SilentlyContinue` found none. Under the task's Windows-mode exception, `swift test --package-path RecalledCore`, `xcodegen && xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build`, and `xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' build` could not be run locally; no toolchain was installed. An inline Python/PyYAML check parsed all three YAML files and asserted target/platform/dependency/configuration/scheme/CI wiring, manifest settings, and Core import boundaries: PASS. `git diff --check`: PASS. These static checks do not substitute for compilation or launch checks.
- Not done / risks / questions for the manager: Push `task/T01-scaffold` and require green `core-tests` and `app-build`; no push or CI execution was performed here. Device signing, App Group provisioning, and app launch still require a Mac. SCXSwiftKit 1.0.0 uses tools 6.2; its Foundation Models provider implementation is guarded for the version-2 module and iOS/macOS 27, while its runtime supports 26. This does not add a provider call to the scaffold, but the later SCX integration task should account for that upstream API limitation. No out-of-scope fixes were made.
- Commit blocker: `git add` failed with `fatal: Unable to create 'C:/Users/User/Desktop/projects/AppleHackathon/.git/index.lock': Permission denied`. The session grants read-only access to `.git` and does not permit approval escalation. No files were staged and no commit was created; cached diff checks therefore provided no validation of these changes. The manager must stage the listed task files and commit as `T01: Scaffold iOS and macOS apps, Core package, and CI` before pushing. The log entry was appended after the failed staging attempt; all task changes remain in the working tree.

## Review (round 1)
- Date: 2026-10-23 14:05 AEDT
- Verdict: PASS
- Evidence: GitHub Actions on task/T01-scaffold, runner macos-26 (Xcode 26.6, build 17F113, Swift 6.3.3): `core-tests` run 39891663423 success (`placeholderProvidesAppName` passed); `app-build` run 39891663440 success (xcodegen, then `Recalled` for iOS Simulator and `RecalledMac` for macOS, unsigned).
- Reviewed project.yml, xcconfig, workflows, sources: matches every criterion. Core has no platform imports. Secrets only via optional include; Secrets.xcconfig and Config/Generated are gitignored.
- One criterion left unticked on purpose: "App launches to a placeholder screen" needs a Mac or iPhone run, which belongs to the owner at the M0 gate. It compiles on both platforms.
- Process note: the Codex sandbox keeps .git read-only (`--add-dir .git` does not help), so the manager committed the round as `T01: Scaffold iOS and macOS apps, Core package, and CI`.
