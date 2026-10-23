# T01: Repo scaffold: XcodeGen project, Core package, Share extension, CI

| Field | Value |
|---|---|
| Status | todo |
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

## Verify
```
swift test --package-path RecalledCore
xcodegen && xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' build
```

## Out of scope
Any feature logic.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->
