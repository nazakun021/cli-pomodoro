# Tech Debt Tracker

Record intentional compromises so later work can distinguish known debt from defects.

## Entries

### Stable releases are not notarized

- **Impact:** Ad-hoc-signed stable builds require manual Gatekeeper trust steps, provide weaker publisher identity assurance, and are distributed through the project tap rather than promising official Homebrew cask acceptance.
- **Owner:** Project maintainers.
- **Revisit when:** Pomo targets a general macOS audience, Gatekeeper setup becomes a recurring support burden, official Homebrew distribution is desired, or Apple Developer enrollment becomes available.
