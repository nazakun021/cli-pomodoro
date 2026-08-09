# 12 — Review weekly history, streaks, and clear summaries

**What to build:** A user can review accurate locale-aware weekly Focus history and streaks, then clear only that history with informed confirmation.

**Blocked by:** 11 — Persist Focus accounting and show today’s summary

**Status:** ready-for-agent

- [ ] The Summary window shows one accessible row for every date in the selected locale-aware week, with detailed Focus time, completed Rounds, weekly totals, and current streak.
- [ ] Previous and next navigate locale-defined calendar weeks, and next is disabled beyond the current week.
- [ ] Detailed Focus uses hours, minutes, and seconds derived from stored milliseconds while the compact menu retains its non-overstating minute format.
- [ ] A date qualifies for streak only through at least one completed Round; partial Focus alone never qualifies.
- [ ] A streak through yesterday remains current during today and resets only after a complete local date is missed.
- [ ] Historical recorded dates and timezone context remain stable after timezone changes, while weekly grouping follows the current locale.
- [ ] Clear History requires confirmation, removes only Summary Records transactionally, and preserves Presets, preferences, and any active Session.
- [ ] Unit and temporary-database tests cover locale first weekdays, empty dates, midnight splits, timezone changes, streak boundaries, totals, rollback, and clear isolation.
- [ ] UI automation verifies resizing, seven-row accessibility, navigation limits, keyboard order, VoiceOver labels, and safe Clear History placement and confirmation.
