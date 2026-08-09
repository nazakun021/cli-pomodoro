# 17 — Install, upgrade, uninstall, and zap through Homebrew

**What to build:** A Homebrew user can install and maintain the same Pomo release artifact while retaining data by default and deleting it only through explicit zap.

**Blocked by:** 16 — Build and verify the universal direct-release artifact

**Status:** ready-for-agent

- [ ] The project-tap cask references the approved universal archive and exact checksum and exposes the bundled CLI plus zsh, bash, and fish completions.
- [ ] A clean cask install yields the same app, CLI product version, checksum evidence, bundle identity, and architecture slices as direct download.
- [ ] Cask caveats explain checksum verification, the unnotarized Open Anyway flow, and the requirement to stop the Session and quit the Agent before upgrade.
- [ ] Install and upgrade scripts never silently terminate the Agent or active Session and never promise automatic database downgrade.
- [ ] Ordinary uninstall removes installed product artifacts while preserving Presets, preferences, Summary Records, backups, and onboarding state.
- [ ] Explicit zap removes only documented Pomo-owned preferences, application support, caches, logs, saved state, and launch-at-login artifacts.
- [ ] Cask syntax, version, checksum, artifact links, completions, caveats, uninstall, zap scope, and upgrade metadata pass automated release checks.
- [ ] Manual clean-profile install, upgrade, uninstall, reinstall, and zap evidence confirms Session protection, data retention, complete explicit removal, CLI exposure, and trust flow.
