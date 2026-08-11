# Tech Debt Tracker

Record intentional compromises so later work can distinguish known debt from defects.

## Entries

### Stable releases are not notarized

- **Impact:** Ad-hoc-signed stable builds require manual Gatekeeper trust steps, provide weaker publisher identity assurance, and are distributed through the project tap rather than promising official Homebrew cask acceptance.
- **Owner:** Project maintainers.
- **Revisit when:** Pomo targets a general macOS audience, Gatekeeper setup becomes a recurring support burden, official Homebrew distribution is desired, or Apple Developer enrollment becomes available.

### Completion notifications cannot be authorized in the validated ad-hoc build

- **Impact:** Xcode-signed and installed ad-hoc Pomo builds return `UNError.notificationsNotAllowed`, create no Notification Center preference record, and cannot validate or deliver allowed-state completion notifications/actions. Timing and the bundled completion chime continue to work.
- **Owner:** Project maintainers.
- **Revisit when:** An Apple Development or Developer ID signing identity becomes available or ADR-0004's signing decision changes. Ticket 09 resolves the ad-hoc MVP through capability gating and non-notification completion feedback; signed notification delivery and actions still require this revisit.
