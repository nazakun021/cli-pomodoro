# ADR-0004: Project Tap and Ad-Hoc Signing

Status: Accepted

## Context

Pomo targets technical macOS users on Apple Silicon and Intel. The native Agent and CLI must remain version-aligned, and installation must place the app where macOS services can launch it while exposing `pomo` on the shell path.

The project will not use Apple Developer ID signing or notarization for current preview or stable releases. Downloaded ad-hoc-signed apps encounter Gatekeeper and quarantine friction, so installation must set accurate expectations and provide tested trust instructions.

## Decision

- Publish one cask in the project Homebrew tap containing a universal Pomo app bundle with both Apple Silicon and Intel code.
- Expose the `pomo` executable and generated zsh, bash, and fish completions through the cask.
- Publish a matching universal app/CLI archive and cryptographic checksums in each GitHub release.
- Ad-hoc sign app and CLI builds with Hardened Runtime enabled. Do not enable App Sandbox because the external CLI/socket model is outside Mac App Store distribution.
- Do not require Apple notarization for stable 1.0. Test and publish Gatekeeper trust steps for each release channel.
- Deliver first-release updates only through Homebrew.
- Require users to stop an active Session and run `pomo quit` before `brew upgrade`. Installation scripts must not silently terminate the Agent.
- Preserve application data on ordinary uninstall. Define cask zap artifacts and an explicit in-app full reset for complete removal.
- Implement opt-in launch at login through the supported macOS 13 service-registration API, not Homebrew services or shell startup files.
- Use bundle identifier `com.nazakun.pomo` and MIT licensing.
- Publish through `nazakun021/homebrew-pomo`, installed as `brew install --cask nazakun021/pomo/pomo`.
- Document only Apple's System Settings → Privacy & Security → Open Anyway trust flow after checksum verification; do not recommend quarantine-removal commands.
- Follow Semantic Versioning with shared app/CLI tags `vMAJOR.MINOR.PATCH`; protocol/database/archive schema versions evolve independently.
- Use GitHub Actions with a protected manual-approval environment to publish the GitHub Release and tap update.

Artifact layout, release checks, trust instructions, and automation are defined by `.scratch/menu-bar-pomodoro/release-design.md`. Workflow implementation details remain task-local.

## Consequences

### Positive

- The app and CLI are installed and upgraded as one compatible unit.
- One universal artifact serves the project tap and direct GitHub release.
- Releases do not depend on Apple Developer enrollment or notarization credentials.
- Hardened Runtime preserves an execution-hardening layer without imposing App Sandbox IPC constraints.
- Ordinary uninstall does not unexpectedly destroy productivity data.

### Negative

- Every release has Gatekeeper/quarantine friction and requires manual trust instructions.
- Users receive weaker publisher identity assurance than a Developer ID-notarized app provides.
- Distribution remains in a project tap rather than promising acceptance into official Homebrew casks.
- Universal artifacts are larger and require both-architecture validation.
- Users must coordinate Agent shutdown before Homebrew upgrades.

## Alternatives considered

### Developer ID signing and notarization

Deferred. It removes recurring Gatekeeper friction and improves publisher trust, but requires Apple Developer enrollment, credential management, and notarization automation.

### Formula builds from source

Not selected because Pomo is primarily a native app bundle with a companion executable, Hardened Runtime requirements, and launch-at-login integration.

### Separate app cask and CLI formula

Rejected because independent versions create avoidable IPC compatibility and support problems.
