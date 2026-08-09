# 16 — Build and verify the universal direct-release artifact

**What to build:** A direct-download user can install one verified universal Pomo artifact containing matching native app, CLI, and completions with honest macOS trust guidance.

**Blocked by:** 15 — Validate complete accessible native and terminal workflows

**Status:** ready-for-agent

- [ ] Packaging produces one versioned universal archive containing only the expected Pomo app bundle with bundled CLI and zsh, bash, and fish completions.
- [ ] App and CLI share one Semantic Version, the approved bundle identity, macOS 13 deployment target, and independently versioned protocol, database, archive, and public schemas.
- [ ] Native app and CLI executable code contain both Apple Silicon and Intel slices and launch natively on required supported hardware.
- [ ] Nested code is signed before the app, and strict verification confirms ad-hoc signing with Hardened Runtime and no false notarization or sandbox claim.
- [ ] Published checksum evidence matches the exact archive, and expansion verifies bundle identity, version, architecture slices, signatures, and absence of unexpected files.
- [ ] Dependency locks, permissive licenses, maintenance/security review, pinned formatting tooling, and clean reproducible rebuild output pass release checks.
- [ ] Direct-install instructions disclose that Apple has not reviewed the app and use checksum verification plus Apple's Open Anyway flow without quarantine-bypass guidance.
- [ ] Automated packaging and release checks run without publishing and retain immutable candidate artifact and evidence identifiers.
- [ ] Manual direct-archive installation validates checksum, first launch, bundled CLI, Agent auto-launch, and Gatekeeper trust flow on required Apple Silicon and Intel coverage.
