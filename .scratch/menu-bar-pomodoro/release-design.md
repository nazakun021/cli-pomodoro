# Pomo Build and Release Design v1

Status: Ready for approval

## Identity and versioning

- Bundle identifier: `com.nazakun.pomo`.
- License: MIT.
- Product versions follow Semantic Versioning and tags `vMAJOR.MINOR.PATCH`.
- App and CLI always share one product version/artifact.
- IPC protocol, database, recovery archive, and public JSON schemas version independently.

## Project layout

- Commit a minimal `Pomo.xcodeproj` for app and XCUITest targets.
- Shared domain, IPC, persistence, terminal renderer, and CLI modules live in local Swift packages.
- Swift language mode is 6 with strict concurrency.
- Development/release baseline is recorded in the repository; initial planning baseline is Xcode 26.4.1 and Swift 6.3.1.
- Deployment target is macOS 13.
- Use pinned Swift Argument Parser, GRDB, and swift-format versions with resolved lock data and license/security review.

## Standard commands

A committed Makefile delegates complex behavior to `scripts/`:

- `make resolve` — resolve pinned packages and verify toolchain.
- `make format` — apply pinned swift-format.
- `make format-check` — strict formatting check.
- `make build` — development app and CLI build.
- `make test-unit` — Swift Testing domain/storage/protocol tests.
- `make test-integration` — real Agent/socket/database tests.
- `make test-cli` — subprocess, TTY, JSON/NDJSON, and exit-code tests.
- `make test-ui` — XCUITest lifecycle/accessibility suite.
- `make schema-check` — parse SQL/JSON schemas and validate all protocol/archive fixtures.
- `make validate` — all non-destructive local quality gates.
- `make package VERSION=x.y.z` — reproducible unsigned/ad-hoc universal archive in `dist/`.
- `make release-check VERSION=x.y.z` — validate version, universal slices, signatures, archive, checksums, cask, and clean install/upgrade metadata without publishing.

CI treats Swift compiler warnings and strict-concurrency diagnostics as errors. Pinned swift-format is the formatting gate; SwiftLint is not initially required.

## Artifact

GitHub release files:

- `Pomo-vMAJOR.MINOR.PATCH-macos-universal.zip`
- `Pomo-macos-arm64.zip`
- `pomo-macos-arm64`
- `install-pomo-macos-arm64.sh`
- `SHA256SUMS`

The universal and arm64 archives each contain one `Pomo.app`; its bundled CLI is
installed into `~/.local/bin/pomo` by the arm64 installer. The raw CLI asset is
for automation only and does not include the menu-bar Agent. Build both `arm64`
and `x86_64` slices for the universal archive, combine/verify universal Mach-O
files, sign nested executable code before the app, then ad-hoc sign with
Hardened Runtime.

Required checks include:

- `lipo -archs` contains `arm64 x86_64` for app/CLI code.
- `codesign --verify --deep --strict` succeeds.
- archive SHA-256 matches `SHA256SUMS`.
- archive expands with expected bundle ID/version and no unexpected files.
- clean cask and direct-archive installations produce identical version/checksum evidence.

`spctl` rejection is expected while unnotarized and does not count as Gatekeeper validation success. Manual trust-flow validation is mandatory.

## Gatekeeper instructions

Before overriding macOS protection, users are told that Apple has not reviewed the app and publisher identity cannot be verified.

Document this flow only:

1. Download from the project GitHub release or install the project cask.
2. Verify the published SHA-256 checksum.
3. Attempt to open Pomo once.
4. Open System Settings → Privacy & Security.
5. In Security, choose Open Anyway within the macOS-offered window, authenticate, and confirm Open.

Reference Apple's current “Open a Mac app from an unknown developer” guidance. Do not recommend `xattr`, `--no-quarantine`, global Gatekeeper disablement, or other quarantine bypasses.

## Homebrew tap

- Tap repository: `nazakun021/homebrew-pomo`.
- Install command: `brew install --cask nazakun021/pomo/pomo`.
- Cask uses the GitHub archive URL and exact SHA-256.
- Cask exposes bundled `pomo` and zsh/bash/fish completions.
- Caveats include checksum/trust instructions and `pomo quit` before upgrade.
- Ordinary uninstall preserves data.
- Zap lists the `com.nazakun.pomo` preferences plus Pomo Application Support, caches, logs, saved state, and launch-at-login registration artifacts.
- Cask scripts never silently terminate an Agent or active Session.

## GitHub Actions release flow

1. Maintainer dispatches release workflow with version and source commit.
2. CI verifies clean version metadata and that the tag does not exist.
3. Run all automated gates and both-architecture builds.
4. Package, sign, verify, checksum, and run `release-check` without publishing.
5. Upload immutable candidate artifacts to a protected GitHub environment.
6. Maintainer reviews evidence and grants manual approval.
7. Workflow creates the version tag and GitHub Release from the approved commit/artifacts.
8. Workflow opens or pushes the exact checksum/version update to `nazakun021/homebrew-pomo`.
9. Post-publish smoke checks download from both channels and compare evidence.

Publishing never rebuilds after approval.

## Upgrade and rollback

- User stops the Session and runs `pomo quit` before `brew upgrade`.
- Cask does not kill Pomo automatically.
- If an older app sees a newer database, it enters Recovery and offers raw database export rather than downgrade.
- Release rollback means reinstalling an older artifact only when database compatibility permits; docs never promise automatic schema downgrade.
