# Recalled for iPhone

Commitments from your messages, read on your phone. Built at AI On Apple, Sydney, 23 to 25 October 2026.

- Product and technical spec: [docs/SPEC.md](docs/SPEC.md)
- Plan and task board: [docs/PLAN.md](docs/PLAN.md)
- How the agent factory works: [docs/FACTORY.md](docs/FACTORY.md)
- Log: [docs/LOG.md](docs/LOG.md)

Prior work: concept and rules come from the Recalled web app (Builders Hack, October 2026). All code in this repo is new and native.

## Generate and run

On a Mac, install Xcode 26 or later and select it as the active developer directory.
The iPhone app requires iOS 26; the native Mac app requires macOS 26.
From the repository root:

```sh
brew install xcodegen && xcodegen
open Recalled.xcodeproj
```

Choose the shared `Recalled` scheme and an iPhone simulator/device, or choose
`RecalledMac` and My Mac, then Run. For device signing, select your development
team for the app and share extension and provision the `group.au.recalled.app`
App Group. The Mac target uses the same SwiftUI sources and does not embed the
iOS share extension. Both apps show on-device language model availability;
unavailability on a simulator or unsupported hardware still permits launch.

`project.yml` is the source of truth. XcodeGen generates the ignored
`Recalled.xcodeproj` and `Config/Generated/` plists and entitlements. Regenerate
after changing the spec; do not hand-edit or commit the generated project.
SCXSwiftKit is pinned to tag `1.0.0`.

Service keys are optional for the scaffold. To configure them, copy
`Secrets.xcconfig.example` to the gitignored `Secrets.xcconfig` and fill in the
values locally. Both app targets use `Config/App.xcconfig`, which optionally
includes that file and exposes `SCX_API_KEY` and `ELEVENLABS_API_KEY` through
Info.plist build-setting substitutions. Never commit real keys.

## Verify

```sh
swift test --package-path RecalledCore
xcodegen && xcodebuild -scheme Recalled -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -scheme RecalledMac -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

The Core package uses Swift tools 6.0 with iOS 18/macOS 15 minimum platforms and
has no Apple UI, Foundation Models, or EventKit dependencies. Its placeholder
test does not require Apple Intelligence or credentials.

Windows development cannot run these Apple toolchain checks. After the manager
pushes the task branch, both `core-tests` and `app-build` GitHub Actions workflows
must pass on `macos-26`. They run on every branch push and pull request; app builds
disable code signing and require no secrets file.
