# 18 — Automate approved releases and run the final quality matrix

**What to build:** A maintainer can approve and publish immutable Pomo artifacts once, then prove GitHub and Homebrew deliver the same fully validated release.

**Blocked by:** 16 — Build and verify the universal direct-release artifact; 17 — Install, upgrade, uninstall, and zap through Homebrew

**Status:** ready-for-agent

- [ ] Manual release dispatch validates version metadata, source commit, absent tag, strict automated gates, and both architecture builds before creating a candidate.
- [ ] Packaging, signing, checksum, and release checks complete before a protected manual approval and expose reviewable immutable evidence.
- [ ] Approval publishes the exact reviewed artifacts without rebuilding, creates the Semantic Version tag and GitHub Release, and updates the project tap with the exact version and checksum.
- [ ] Post-publish checks download both GitHub and Homebrew deliveries and prove artifact, version, checksum, bundle identity, CLI, completions, and architecture equivalence.
- [ ] The final automated matrix passes schema semantics, unit, integration, CLI, UI, clean build, packaging, signatures, cask, dependency, and performance gates.
- [ ] The final manual matrix records clean-profile onboarding, sleep, alerts, sound, login, accessibility appearances, Gatekeeper, direct install, Homebrew lifecycle, mismatch, and Recovery scenarios.
- [ ] Stable evidence covers required Apple Silicon and Intel hardware on macOS 13 and current supported releases, with unavailable coverage blocking publication.
- [ ] Release notes state the ad-hoc Hardened Runtime signature, intentional lack of notarization and sandboxing, Homebrew-only updates, checksum verification, data-preserving uninstall, and explicit zap behavior.
- [ ] A final publication audit confirms warnings and strict-concurrency diagnostics are errors, candidate provenance is unchanged, and no release-only step mutates or rebuilds approved content.
