# Spec: Menu Bar Pomodoro

Status: ready-for-agent

## Problem Statement

Technical macOS users need a Pomodoro product that works equally well from the terminal and the menu bar without tying an active Session to a Terminal process. Existing foreground-only CLI approaches lose timing state when Terminal closes, while third-party menu-bar hosts cannot provide the required native lifecycle, settings, accessibility, notification, persistence, and release behavior.

Pomo must therefore provide one durable local authority for Session state and expose two consistent control surfaces. The product must preserve accurate Phase timing through delayed callbacks and Mac sleep, account for completed and interrupted Focus work without inventing completed Rounds, remain automatable through stable versioned output, recover safely from durable-data failures, and install as one coherent macOS app and CLI artifact. It must do so without cloud services, account creation, detailed activity surveillance, or restoration of volatile Sessions after Agent or Mac restart.

The first release is complete only when the CLI, terminal UI, native menu UI, persistence model, Recovery model, protocol schemas, accessibility behavior, packaging, trust flow, and validation evidence agree on the same observable semantics.

## Solution

Pomo is a native, menu-bar-only macOS product with a persistent Agent and a companion `pomo` CLI. The Agent is the sole owner of authoritative Session state, Phase deadlines, serialized mutations, notifications, sounds, settings, summaries, and local persistence. The CLI is a short-lived command surface or an explicitly attached observer; closing it never ends an Agent-owned Session.

Users can start from an interactive terminal wizard, an explicit non-interactive command, an idle-menu Quick Start, or a compact Custom Session popover. Every start resolves a Preset and one-time overrides into a complete immutable Session Configuration. The same state machine governs Ready, Running, Paused, Idle, and blocked Recovery behavior across both interfaces.

The Agent and CLI communicate over a private same-user local socket using negotiated, length-prefixed, versioned JSON messages. Commands return stable responses and snapshots; Follow produces ordered events. Public automation uses one versioned JSON envelope per ordinary command and NDJSON for Follow. Mutations carry Agent-bound request identifiers and have bounded idempotent retry semantics.

Presets, default selection, accepted-start recency, and finalized Focus contributions are stored transactionally in SQLite. Lightweight preferences and a minimal non-restorable interruption marker use macOS preferences. A monotonic deadline controls active timing; wall-clock values are presentation estimates and recorded accounting context. Required accounting or database failures enter capability-driven Recovery rather than silently losing, resetting, or mutating data.

The product is delivered as one universal native app bundle containing the matching CLI and shell completions. Homebrew is the update mechanism. Releases are ad-hoc signed with Hardened Runtime, intentionally unnotarized, checksum-verifiable, and accompanied by tested Apple Gatekeeper trust instructions.

## User Stories

1. As a terminal-first user I want to start Pomo interactively with a bare command, so that I can configure a Session without memorizing flags.
2. As a terminal-first user I want the interactive setup to require a TTY, so that unattended processes never hang waiting for input.
3. As a terminal-first user I want non-TTY interactive attempts to show explicit alternatives, so that I can switch to an automatable command.
4. As a terminal-first user I want a plain line-oriented setup mode, so that I can work in terminals that cannot safely render an alternate screen.
5. As a screen-reader user I want plain mode to expose equivalent choices and defaults, so that terminal setup remains understandable without spatial rendering.
6. As an interactive user I want to choose the default, a recent, another named, or a custom Preset, so that common and exceptional Sessions are both quick to start.
7. As an interactive user I want to review all effective Session values before starting, so that I understand exactly what the Agent will run.
8. As an interactive user I want invalid fields to retain focus and preserve my other entries, so that correcting one value does not discard my work.
9. As an interactive user I want replacement confirmation when a Session already exists, so that a bare command cannot silently interrupt active Focus.
10. As an interactive user I want replacement confirmation to be impossible to bypass with a flag, so that only explicit non-interactive Start supports forced replacement.
11. As a keyboard user I want arrows, Tab, Shift-Tab, Space, Enter, Escape, and contextual help to behave consistently, so that I can complete setup without a mouse.
12. As a terminal user I want cancellation and signals to restore cooked input, cursor visibility, style, and the previous screen, so that Pomo never leaves my terminal damaged.
13. As a terminal user I want resize guidance below the supported dimensions, so that wizard state is preserved until the interface can render safely.
14. As a terminal user I want Unicode and color to degrade to ASCII and no-color output, so that meaning survives terminal capability differences.
15. As a command-line user I want to start with a direct Focus duration, so that a common one-off Session requires minimal syntax.
16. As a command-line user I want a direct Focus duration to inherit all other default Preset values, so that shorthand does not create an incomplete configuration.
17. As a command-line user I want to start from a named Preset, so that reusable timing choices work outside the UI.
18. As a command-line user I want one-Session overrides for all durations, cadence, boundary, and automatic transitions, so that I can vary a Session without editing its Preset.
19. As a command-line user I want duration values from one second through twenty-four hours with composable integer units, so that valid timing is flexible and unambiguous.
20. As a command-line user I want malformed, zero, negative, fractional, unitless, and excessive durations rejected as usage errors, so that invalid timing never reaches Agent state.
21. As a command-line user I want finite Rounds and open-ended mode to be mutually exclusive, so that every Session has exactly one boundary model.
22. As a command-line user I want positional Focus duration and explicit Focus override to conflict, so that command precedence is never ambiguous.
23. As a command-line user I want Start to fail when a Session exists unless replacement is explicit, so that scripts cannot interrupt work accidentally.
24. As a command-line user I want successful Start to acknowledge and exit by default, so that ordinary commands remain short-lived.
25. As a command-line user I want Start to launch the installed Agent when necessary, so that I do not need a separate startup step.
26. As a command-line user I want cold Agent Start acknowledged within three seconds or failed clearly, so that automation has a bounded wait.
27. As a user I want every start path to resolve one complete immutable Session Configuration, so that later Preset edits cannot change active behavior.
28. As a user I want at most one active Session, so that menu and CLI controls cannot diverge between competing timers.
29. As a user I want one Round to mean one naturally completed Focus Phase, so that progress and cadence have a precise definition.
30. As a user I want a finite Session to end immediately after its final Focus completes, so that it does not create an unwanted trailing Break.
31. As a user I want an open-ended Session to continue until I stop it, so that I can work without choosing a Round limit.
32. As a user I want Classic to provide 25-minute Focus, 5-minute Short Break, and 15-minute Long Break every four completed Rounds, so that the standard workflow is available immediately.
33. As a Classic user I want Breaks to auto-start and Focus Phases to wait Ready, so that rest begins automatically while work begins deliberately.
34. As a user I want Ready to show the upcoming Phase at full duration, so that it is distinct from Idle and Paused.
35. As a user I want Resume to start either a Ready or Paused Phase, so that one control covers both valid transitions.
36. As a user I want Pause to freeze a Running Phase, so that an interruption does not consume Focus or Break time.
37. As a user I want Skip to work from Ready, Running, or Paused, so that Phase advancement is independent of run state.
38. As a user I want skipping Focus to preserve elapsed Focus without completing a Round, so that time worked is counted without overstating cadence progress.
39. As a user I want skipping a Break to select a Ready Focus Phase, so that the next work interval waits for deliberate start.
40. As a user I want Stop to finalize eligible partial Focus and end the Session, so that interrupted work contributes to summaries.
41. As a CLI user I want explicit Stop to act without another prompt, so that command semantics remain direct and scriptable.
42. As a menu user I want Stop to require confirmation that names partial-Focus impact, so that an accidental click does not end my Session.
43. As a user I want replacing during Focus to finalize only elapsed Focus and not a Round, so that replacement accounting is accurate.
44. As a user I want replacing during a Break to create no contribution, so that summaries contain only Focus work.
45. As a user I want replacement to preserve all previously committed summaries, so that creating a new Session cannot rewrite history.
46. As a user I want a replacement Session prevalidated before old Focus is finalized, so that an invalid replacement cannot terminate valid work.
47. As a user I want successful replacement acknowledged only after accounting and serialized state swap complete, so that success means the new Session is observable.
48. As a user I want closing Terminal to leave my Session running, so that timing belongs to the Agent rather than a shell process.
49. As a user I want Mac sleep to pause a Running Phase with its positive pre-sleep remainder, so that sleeping time is not consumed.
50. As a user I want a Phase whose deadline precedes observed sleep to complete first, so that sleep races preserve elapsed-time truth.
51. As a user I want system wall-clock changes not to alter Phase duration, so that changing timezones or the clock cannot shorten or extend work.
52. As a user I want expected transition wall time recalculated from monotonic remainder, so that displayed estimates remain useful after wall-clock changes.
53. As a user I want whole-second display rounded up until transition, so that `00:00` appears only when completion occurs.
54. As a menu-bar user I want remaining time formatted as `MM:SS` or `H:MM:SS`, so that short and long Phases remain readable.
55. As a menu-bar user I want Idle to show only the app icon, so that Pomo remains available without implying an active Session.
56. As a menu-bar user I want restrained phase and play-pause symbols, so that state is quickly recognizable in macOS appearances.
57. As a VoiceOver user I want every symbol-only state to have a meaningful label and value, so that state never depends on vision.
58. As a menu user I want default Quick Start first and up to three distinct recent non-default Presets next, so that likely starts require little navigation.
59. As a menu user I want Classic eligible for recents when it is not the default, so that built-in and user Presets follow the same duplicate rule.
60. As a user I want accepted starts from every surface to update recency before acknowledgment, so that ordering is consistent across interfaces and restart.
61. As a user I want recency to remain convenience metadata after an ambiguous crash, so that it never falsely claims a volatile Session survived.
62. As a menu user I want deleted Presets removed from recents and the current default excluded, so that Quick Start has no stale or duplicate entries.
63. As a menu user I want Custom Session in a compact status-item popover, so that one-off setup does not require opening Settings.
64. As a menu user I want Custom Session to support Start Once and Save as Preset, so that I can choose between temporary and reusable configuration.
65. As an active user I want Phase state, remaining time, Round progress, primary control, Skip, Stop, and next Phase ordered predictably, so that frequent actions are easy to scan.
66. As an active user I want the primary control to read Start, Pause, or Resume according to state, so that the offered action is always valid.
67. As a user I want the compact menu summary to show today's Focus minutes, completed Rounds, and current streak, so that progress is visible without opening a window.
68. As a user I want positive sub-minute totals shown as `<1m` and whole minutes floored, so that compact summaries never overstate Focus.
69. As a user I want detailed Focus totals shown as `h:mm:ss`, so that persisted millisecond precision has an honest readable presentation.
70. As a user I want previous and next locale-aware week navigation with one row per date, so that weekly history is predictable and complete.
71. As a user I want next-week navigation disabled beyond the current week, so that the summary window does not imply future records.
72. As a user I want weekly totals to follow my macOS locale first weekday, so that summaries align with my calendar conventions.
73. As a user I want completed Rounds assigned to the local date of Focus completion, so that streak qualification is deterministic.
74. As a user I want cross-midnight Focus split across recorded local dates, so that daily Focus totals reflect when work occurred.
75. As a traveling user I want historical timezone and offset context retained, so that later timezone changes do not regroup past totals.
76. As a user I want partial Focus to add time without qualifying a streak date, so that streaks represent completed Rounds.
77. As a user I want yesterday's qualifying streak to remain current through today, so that the streak does not reset before today is over.
78. As a user I want Clear History to delete only Summary Records after confirmation, so that Presets, preferences, and active work remain intact.
79. As a user I want Summary Records retained locally until I clear them, so that Pomo has no hidden retention or cloud policy.
80. As a user I want to create, duplicate, edit, delete, and select default Presets, so that reusable workflows remain manageable.
81. As a user I want user Preset names unique under case-insensitive comparison, so that selection is unambiguous.
82. As a user I want Classic immutable and undeletable but duplicable, so that the built-in baseline remains recoverable and customizable.
83. As a user I want to edit or delete a source Preset during its active Session, so that immutable Session Configuration protects current timing.
84. As a user I want deleting the default user Preset to confirm and atomically select Classic, so that a valid default always exists.
85. As a user I want deleting a Preset to remove its recency in the same transaction, so that durable references remain consistent.
86. As a first-time user I want a compact welcome popover that identifies Pomo and offers Classic, so that I can find and start the menu-bar app.
87. As a first-time user I want launch at login offered once and off by default, so that registration requires explicit consent.
88. As a user I want launch at login controlled through supported macOS service registration, so that Pomo does not modify shell startup files.
89. As a user I want registration failures shown in Settings and Doctor, so that optional startup behavior is diagnosable.
90. As a user I want notification and sound preferences enabled by default and independently disableable, so that completion feedback matches my environment.
91. As a user I want a subtle bundled completion chime using normal macOS output volume, so that repeated alerts are unobtrusive and predictable.
92. As a first-Session user I want notification purpose explained before permission is requested, so that authorization is informed.
93. As a first-Session user I want timing to start regardless of permission response timing, so that the system prompt cannot block the Session.
94. As a user I want pending-permission completions skipped rather than queued, so that stale notifications never arrive later.
95. As a user I want menu feedback and enabled sound despite pending or denied notifications, so that Phase completion remains observable.
96. As a user I want a temporary non-color missed-alert indicator after a pending-permission completion, so that I know a notification was unavailable.
97. As a user I want opening the menu or explicitly dismissing to clear the missed-alert indicator, so that acknowledgment is under my control.
98. As a VoiceOver user I want the missed-alert indicator announced without changing Phase state, so that accessibility feedback does not mutate timing.
99. As a user with denied notifications I want Alerts to offer Open System Settings, so that permission recovery is actionable.
100. As a Ready-state user I want completion notifications to offer Start Next Phase, so that the notification action is valid and useful.
101. As an auto-transition user I want completion notifications to open current status without a stale Start action, so that notification actions match Agent state.
102. As a Follow user I want a compact observer dashboard with Phase, time, progress, Rounds, next Phase, and recent transitions, so that I can monitor without log spam.
103. As a Follow user I want help and detach to be the only dashboard actions, so that observation cannot accidentally mutate the Session.
104. As a Follow user I want explicit CLI control hints, so that I know how to mutate state from another command.
105. As a Follow user I want Control-C, `q`, or Escape detachment to leave the Session running, so that ending observation is not Stop.
106. As a Follow user I want exactly one concise final scrollback line, so that terminal history is useful without replaying the dashboard.
107. As a plain Follow user I want only initial state, durable transitions, Recovery changes, and terminal events, so that output avoids one-second spam.
108. As a JSON Follow consumer I want schema-versioned NDJSON beginning with the current snapshot, so that streaming automation can initialize deterministically.
109. As a JSON Follow consumer I want stale ticks coalesced but transitions and terminal events ordered, so that backpressure does not erase domain changes.
110. As a slow Follow consumer I want a stable terminal backpressure error and disconnect, so that the Agent never blocks Session processing.
111. As a Follow consumer I want no automatic reconnect after backpressure, so that I explicitly reconcile with Status before observing again.
112. As a Follow user I want Recovery entry to keep the stream connected while ticks stop, so that I can observe Retry resolution or a terminal outcome.
113. As an automation author I want every ordinary JSON command to emit one parseable success or error envelope, so that standard output remains machine-safe.
114. As an automation author I want human errors on standard error and machine errors on standard output in JSON mode, so that stream ownership is stable.
115. As an automation author I want stable exit categories for success, unexpected failure, usage, invalid state, Agent unavailability, protocol mismatch, Recovery, and permission failure, so that scripts can branch reliably.
116. As an automation author I want Status to represent Agent-not-running successfully without launching it, so that observation has no startup side effect.
117. As an automation author I want snapshots to include opaque occurrence IDs, effective Configuration, progress, timing, and revision, so that observations can be reconciled without internal clock leakage.
118. As an automation author I want expected transition time null outside Running, so that estimates are not mistaken for authoritative deadlines.
119. As an automation author I want additive schema evolution within a major version, so that compatible consumers survive new fields.
120. As an automation author I want semantic changes to require a new major schema, so that existing field meanings never drift silently.
121. As a user I want invalid-state errors to report current state and valid next actions, so that recovery from command mistakes is clear.
122. As a user I want protocol mismatch rejected before mutation with both product versions and guidance, so that mixed installations fail safely.
123. As a user I want duplicate mutating request IDs to return their cached outcome during the retry window, so that a lost response cannot apply an action twice.
124. As a user I want expired, future-dated, or wrong-Agent mutation requests rejected, so that stale commands cannot affect a new Agent instance.
125. As a user I want concurrent menu and CLI actions serialized and revalidated, so that one monotonic revision orders every mutation.
126. As a user I want only my account to access the runtime directory, lock, and socket, so that local control is same-user private.
127. As a user I want stale-socket cleanup gated by ownership and exclusive lock acquisition, so that startup cannot remove a live Agent endpoint.
128. As a user I want malformed, truncated, oversized, invalid-encoding, and schema-invalid frames disconnected, so that untrusted local input cannot destabilize the Agent.
129. As a user I want repeated app launches to reuse the existing Agent, so that a second state owner cannot appear.
130. As a user I want active Sessions discarded after Agent or Mac restart, so that Pomo never reconstructs timing it cannot prove.
131. As a user I want an unexpected active-Session crash reported once on next launch, so that loss is visible without pretending the Session is recoverable.
132. As a user I want the interruption marker to omit Session Configuration and remaining time, so that it cannot become accidental restoration state.
133. As a user I want intentional Quit during a Session protected by confirmation or force, so that Agent shutdown cannot silently discard work.
134. As a user I want intentional Quit to finalize eligible Focus before discarding the Session, so that deliberate shutdown preserves completed accounting work.
135. As a user I want Doctor to inspect installation, versions, protocol, socket, data, login registration, and notifications without repair, so that diagnosis has no mutation side effects.
136. As a user I want optional notification and login denial reported as warnings, so that healthy core operation still exits successfully.
137. As a user I want core filesystem or socket permission failures classified distinctly, so that access problems are scriptable.
138. As a user I want Presets and Focus contributions committed transactionally, so that crashes cannot leave partial durable operations.
139. As a user I want accepted-start recency committed transactionally before success acknowledgment, so that all start surfaces share durable ordering.
140. As a user I want zero-elapsed interrupted Focus to create no contribution, so that storage contains only positive work.
141. As a user I want each Focus segment uniquely keyed by Phase and segment index, so that retry cannot double-count accounting.
142. As a user I want at most one completed-Round marker per source Focus Phase, so that cadence and summaries cannot duplicate completion.
143. As a user I want database foreign keys, full synchronization, owner-only permissions, and one writer, so that local durable state has explicit integrity boundaries.
144. As a user I want a consistent versioned backup before migration, so that schema evolution has a recoverable pre-change artifact.
145. As a user I want each forward migration applied transactionally and backups retained by policy, so that upgrade failures preserve diagnosable data.
146. As a user I want a newer unknown schema opened only in read-only Recovery, so that an older app never attempts downgrade.
147. As a user I want required accounting failure to block before Phase transition, so that visible state cannot advance ahead of required summaries.
148. As a user I want pending accounting and its intended next state retained in memory during Recovery, so that Retry can complete exactly once and continue deterministically.
149. As a user I want ordinary timing and mutation stopped in Recovery, so that blocked accounting cannot accumulate conflicting work.
150. As a user I want Recovery to expose only capabilities valid for its reason, so that unavailable actions are never offered.
151. As a user I want accounting Recovery to offer Retry, export, Discard Session, and Reset Data, so that I can choose preservation, limited loss, or full reset.
152. As a user I want migration Recovery to omit Discard Session, so that a data migration problem is not misrepresented as volatile Session loss.
153. As a user I want unknown-schema Recovery to offer raw export rather than semantic JSON, so that Pomo does not claim to understand newer data.
154. As a user I want corrupt-database Recovery capabilities based on available evidence, so that best-effort export and pending-Session discard remain honest.
155. As a user I want accounting Retry idempotent across database and IPC retry mechanisms, so that successful recovery applies one contribution.
156. As a user I want successful accounting Retry to enter the already-determined next state, so that recovery does not recalculate Session behavior.
157. As a user I want successful migration Retry to return the Agent to Idle, so that no volatile Session is invented during startup repair.
158. As a user I want Discard Session to lose only pending uncommitted Focus, so that committed data, Presets, and preferences remain intact.
159. As a user I want Reset Data visually and verbally distinct from Discard Session, so that limited Session loss cannot be confused with full deletion.
160. As a user I want export-first guidance before destructive Recovery actions, so that data preservation is encouraged without making Discard mandatory.
161. As a user I want pending accounting Recovery lost after Agent restart with one interruption notice, so that volatile recovery state follows the no-restoration rule.
162. As a user I want intentional Quit refused during unresolved pending accounting, so that required writes cannot be bypassed accidentally.
163. As a user I want known-schema Recovery export to contain versioned semantic JSON and a hash manifest, so that understood data is portable and integrity-checkable.
164. As a user I want unknown or unreadable database export to contain hashed raw database material and explanatory metadata, so that opaque evidence is preserved honestly.
165. As a user I want archive paths, sizes, and hashes validated against an allowlist, so that Recovery bundles cannot contain ambiguous or escaping entries.
166. As a user I want Full Reset available only while Idle or explicitly advertised by Recovery, so that normal active Sessions cannot be erased underneath themselves.
167. As a user I want Full Reset confirmation to name Presets, preferences, summaries, and onboarding, so that destructive scope is explicit.
168. As a user I want ordinary uninstall to preserve my local data, so that removing the app is not the same as deleting history.
169. As a user I want explicit zap or Full Reset to remove documented Pomo-owned data, so that complete removal remains possible.
170. As a keyboard-only native UI user I want every menu, popover, Settings tab, confirmation, and summary control reachable, so that all core workflows are operable without a pointer.
171. As a VoiceOver user I want concise state-change announcements without one-second tick announcements, so that feedback remains useful rather than noisy.
172. As a user with Reduce Motion enabled I want nonessential transitions disabled, so that Pomo honors system accessibility preferences.
173. As a user with Increase Contrast or dark appearance enabled I want native controls and symbols to remain legible, so that the UI follows macOS presentation needs.
174. As a user I want state, validation, warnings, and destructive meaning never encoded by color alone, so that every decision has a non-color cue.
175. As a user I want Settings organized into General, Presets, and Alerts, so that configuration follows a predictable native hierarchy.
176. As a user I want Recovery shown in the status item and menu without a forced modal, so that failure is visible without stealing focus.
177. As a Recovery user I want actions ordered Retry, Export, Discard Session, and Reset Data when available, so that preservation precedes destruction.
178. As a macOS 13 user I want Pomo to run on Ventura and newer supported releases, so that the stated deployment baseline is real.
179. As an Apple Silicon user I want the same release artifact as Intel users, so that installation guidance and versions remain unified.
180. As an Intel Mac user I want native code in the universal release, so that support does not depend on emulation.
181. As a Homebrew user I want one cask to install the app, CLI, and shell completions, so that both interfaces remain version-aligned.
182. As a direct-download user I want the same universal app artifact and checksum evidence as Homebrew, so that release channels are comparable.
183. As a security-conscious user I want ad-hoc signing with Hardened Runtime and explicit unnotarized status, so that release assurances and limitations are honest.
184. As a Gatekeeper user I want checksum verification and Apple's Open Anyway flow documented, so that trust is established without quarantine-bypass commands.
185. As a Homebrew user I want package scripts never to terminate my Agent silently, so that upgrades cannot discard a Session behind my back.
186. As a Homebrew user I want instructions to stop my Session and quit the Agent before upgrade, so that version replacement is deliberate.
187. As a user I want updates delivered only through Homebrew in the first release, so that there is one supported update mechanism.
188. As a user I want app and CLI product versions to match while protocol and data schemas version independently, so that release identity and compatibility identity remain distinct.
189. As a maintainer I want a protected manual approval before publishing immutable artifacts, so that reviewed evidence is the exact release content.
190. As a maintainer I want publishing to reuse approved artifacts without rebuilding, so that release provenance remains stable.
191. As a maintainer I want post-publish downloads from both channels compared, so that cask and GitHub distribution cannot drift.
192. As a maintainer I want warnings and strict-concurrency diagnostics treated as errors, so that Swift 6 concurrency correctness is enforced.
193. As a maintainer I want dependencies and formatting tools pinned and reviewed for license, maintenance, and security, so that builds remain reproducible and supportable.
194. As a maintainer I want Idle operation without timer polling and near-zero CPU, so that a persistent Agent is unobtrusive.
195. As a maintainer I want sustained active CPU above one percent investigated, so that countdown rendering remains efficient.
196. As a local user I want ordinary Agent commands to complete within 200 milliseconds under typical conditions, so that both interfaces feel immediate.
197. As a user I want awake deadline transition handling within 250 milliseconds under typical conditions, so that visual and alert feedback tracks actual completion.
198. As a release reviewer I want unavailable required hardware or operating-system coverage treated as a blocker, so that support claims are not silently waived.

## Implementation Decisions

- The persistent native Agent is the sole authority for Session state, Phase timing, notifications, sound, persistence, Recovery, settings, and summaries. The CLI and native UI are adapters over that authority and never own parallel Session state.
- The implementation uses Swift 6 strict concurrency, a shared Swift package for domain and protocol behavior, SwiftUI with AppKit where native lifecycle requires it, Swift Argument Parser for the CLI, a small internal ANSI and terminal-control renderer for human TUI behavior, and GRDB behind domain-owned persistence interfaces.
- One Agent instance is enforced with a same-user advisory lock and local socket. Repeated app launches reuse the existing Agent and forward their requested action. Runtime directories, locks, and sockets require effective-user ownership and owner-only permissions.
- IPC protocol v1 uses a four-byte unsigned big-endian length followed by UTF-8 JSON, with a one-mebibyte payload maximum. Invalid lengths, truncation, encoding, JSON, or schema terminate the connection without reflecting untrusted payload text to users.
- Handshake negotiation selects the highest mutually supported minor version within a shared major and intersects explicit capabilities. A major mismatch or missing required capability rejects the command before mutation. Product versions are diagnostic and do not substitute for protocol compatibility.
- Ordinary IPC connections perform one handshake, one request, one terminal response, and close. Follow connections add an initial snapshot, Running ticks, ordered transitions, and one terminal event.
- The Agent serializes every menu and CLI mutation, revalidates it against current state, and increments a monotonic state revision for domain mutations. Display ticks may retain the same revision.
- Every mutating request carries a canonical lowercase request UUID, millisecond UTC issue time, and negotiated Agent instance ID. The five-minute retry window accepts only the same ID, returns its cached terminal outcome, rejects IDs older than five minutes or over thirty seconds in the future, and rejects IDs bound to another Agent instance.
- Follow emits a tick only when the rounded Running display second changes. Each follower has one replaceable tick slot and a FIFO of sixty-four non-coalescible events. Overflow attempts a terminal backpressure event, disconnects that follower, and cannot block Agent mutation.
- Public ordinary JSON is one schema-versioned response envelope. Public Follow is schema-versioned NDJSON. Public and IPC envelopes remain distinct while sharing snapshot, Configuration, action-result, doctor-result, and error models.
- Schema v1 objects reject additional properties except where negotiated additive evolution explicitly permits them. UUIDs are canonical lowercase text, wall times are UTC RFC 3339 with exactly millisecond precision, response result and error are mutually exclusive, and command result families must match their commands.
- Session Configuration has exactly one boundary: open-ended with no target or finite with a target of at least one. Preset and nullable overrides resolve fully before Agent mutation.
- Snapshot fields are required and nullable according to a strict state matrix. Not-running is synthesized only by the CLI; Idle has Agent identity but no Session data; Session snapshots contain complete Session and Phase data; accounting Recovery retains blocked Session data; migration and newer-schema Recovery do not invent Session data.
- Event sequences begin at zero and increase without gaps among emitted events. Replaced ticks do not consume visible sequence numbers. Initial, tick, transition, terminal, backpressure, Recovery-entered, and Recovery-resolved events obey their defined snapshot and error combinations.
- Active Session state is memory-only. Clean and unclean Agent or Mac restart discard it. A minimal preference marker records only prior Agent identity, active-Session presence, and clean-exit metadata for one concise interruption notice.
- A Running Phase is represented by a monotonic deadline. Remaining time derives from that deadline, whole-second display rounds upward, and expected wall transition is only an estimate. Sleep completes a deadline reached at or before observed sleep; otherwise it captures positive remainder and wakes Paused.
- Start resolves an immutable Session Configuration. Classic is a protected built-in Preset with 25-minute Focus, 5-minute Short Break, 15-minute Long Break, cadence four, finite four-Round default, automatic Breaks, and Ready Focus transitions.
- Resume is valid from Ready or Paused, Pause only from Running, and Skip from Ready, Running, or Paused. Natural Focus completion alone advances completed Rounds and long-Break cadence. Final finite Focus ends the Session without a trailing Break.
- Replacement validates and constructs the new Session first, commits eligible old Focus accounting, performs an infallible serialized volatile swap, then acknowledges. Durable commit and volatile swap are deliberately ordered rather than falsely described as one atomic transaction.
- SQLite owns Presets, default selection, accepted-start recency, and Focus contributions. macOS preferences own lightweight global settings, onboarding, and the interruption marker. The Agent is the only writer.
- Writable database connections enable foreign keys, write-ahead logging, and full synchronous durability. Data directories and files are owner-only. The protected Classic row has a stable identity and database-level edit and delete protection.
- Preset duration fields store positive integer seconds up to twenty-four hours. A locale-independent case-folded key enforces name uniqueness. The finite/open-ended check is enforced physically as well as semantically.
- Exactly one existing Preset is default. Deleting the default user Preset selects Classic and removes the deleted row and its recency in one transaction.
- Accepted Session creation increments a monotonic sequence and assigns it to the source Preset transactionally before acknowledgment. Recency can survive an ambiguous pre-acknowledgment crash and never proves that volatile Session state survived. The UI selects the three highest distinct non-default entries.
- Focus contributions store positive integer milliseconds, source Phase identity, segment index, recorded local date, timezone identifier, UTC offset, completion marker, and finalization time. Unique Phase-segment keys make accounting retry idempotent, and a partial unique constraint permits at most one completion marker per Phase.
- All midnight-split rows for one Focus Phase are computed before and committed in one transaction. Only the segment containing natural completion carries the Round marker. Zero elapsed interruption creates no row, and later timezone changes never regroup history.
- Preset mutation, default selection, accepted-start recency, Focus finalization, history clearing, and each named migration are transaction boundaries. Session state changes that require accounting occur only after the write commits.
- Before pending migrations, the Agent creates a consistent versioned backup through the database backup mechanism. Migrations are named, ordered, forward-only, and transactional. Successful upgrades retain the latest three backups; the backup associated with a failed migration is never automatically deleted.
- Required accounting failure occurs before the intended Phase or Session transition and enters blocked Recovery with pending contribution and precomputed next state in memory. Timing, normal mutations, and intentional Quit stop until the state is retried, discarded, or reset.
- Recovery is descriptor-driven. Accounting failure supports Retry, semantic export, Discard Session, and Reset Data. Known-schema migration failure supports Retry, semantic export, and Reset Data. Newer unknown schema supports raw export and Reset Data. Corrupt or unreadable data offers only capabilities supported by available evidence.
- Accounting Retry uses the same Phase and segment identities, applies pending contribution exactly once, and then enters the already-determined next state. Migration Retry returns Idle. Pending accounting Recovery does not survive restart and produces the normal one-time interruption notice.
- Discard Session confirms and loses only pending uncommitted Focus, preserves all committed data, and returns Idle. Reset Data is a separate stronger action available only while Idle or capability-advertised Recovery; it removes all owned durable state and preferences, then recreates schema v1 and Classic.
- Recovery export is a versioned archive with a manifest containing unique allowlisted relative paths, exact byte sizes, and lowercase SHA-256 hashes. Known schemas export semantic data including user Presets, default and recency metadata, separate Classic recency, exportable preferences, and Focus contributions. Unknown or unreadable schemas export a raw database and available sidecars or a consistent raw copy. Import is not implemented in the first release.
- The terminal wizard is a three-step Preset, Configure, and Review flow with stable header, progress, content, validation, and contextual footer regions. It preserves state during resize, has an alternate-screen minimum of sixty columns by eighteen rows, and offers equivalent plain prompts.
- Terminal cleanup is one idempotent main-loop path for completion, cancellation, Control-C, handled signals, disconnect, rendering failure, and input failure. Signal handlers only notify the main loop. The renderer honors no-color preference, capability-based Unicode fallback, logical focus, and non-color meaning.
- The Follow dashboard is observer-only. It displays Phase and state, large remaining time, progress, Round boundary, next Phase, recent transitions, and command hints. Help and detach are its only inputs. Ready and Paused do not poll or redraw.
- Recovery entry keeps Follow connected, stops ticks, and presents an observer Recovery dashboard until resolution, terminal event, transport failure, or detach. Plain Follow emits durable state changes only. Every Follow exit restores the terminal and prints one concise outcome line.
- The native UI is a quiet macOS utility using system typography, materials, controls, accent behavior, SF Symbols, focus rings, and accessibility sizing. It supports light, dark, Increase Contrast, Reduce Motion, keyboard operation, VoiceOver grouping, and non-color meaning without decorative panels or custom-font dependency.
- Idle and active menus use the defined information hierarchy. Custom Session and Welcome use compact 360-point popovers with content scrolling below primary actions when needed. Settings uses General, Presets, and Alerts. Summary is resizable with a seven-row accessible weekly table, weekly totals, current streak, and Clear History separated from navigation.
- Notification permission is explained on first Session start without delaying timing. Pending completions are skipped rather than queued and create an accessible temporary missed-alert indicator while menu feedback and enabled sound continue. Denial exposes system settings. Only Ready notifications expose Start Next Phase.
- Notifications and the bundled chime are globally toggleable and enabled by default. Sound uses ordinary macOS output volume. Launch at login is opt-in through the supported service-registration API and exposes failures without turning an optional denial into core failure.
- Full reset is unavailable during a normal active Session. Clear History removes contributions only. Ordinary uninstall preserves data; explicit zap and confirmed Full Reset remove documented owned data.
- The deployment target is macOS 13. The app bundle and CLI share one Semantic Version and ship as universal Apple Silicon and Intel code. Protocol, database, archive, and public JSON schemas version independently.
- Releases contain one app bundle with the CLI and zsh, bash, and fish completions exposed by one project-tap cask. The same universal archive and checksum evidence are published through GitHub.
- Preview and stable builds are ad-hoc signed with Hardened Runtime, are not sandboxed, and are intentionally not notarized. Gatekeeper guidance requires checksum verification and Apple's Open Anyway flow and never recommends quarantine removal or global protection disablement.
- Homebrew is the only first-release update mechanism. Package scripts never terminate the Agent. Users stop active work and quit before upgrade. Publishing uses approved immutable artifacts, a protected manual gate, exact tap metadata, and post-publish channel comparison.

## Testing Decisions

- The primary and highest testing seam is the Agent command/snapshot/event contract. Most behavior is proven by driving typed commands into an in-process or isolated Agent harness and asserting schema-valid responses, complete snapshots, monotonic revisions, and ordered events. This seam owns state transitions, Configuration resolution, invalid-state guidance, replacement ordering, request idempotency, timing outcomes, Follow semantics, Recovery capabilities, and parity between CLI and menu actions.
- Contract fixtures cover every command, success family, stable error category, state matrix, finite and open-ended Configuration, handshake outcome, event family, public envelope, Recovery descriptor, duplicate and expired request, wrong Agent, malformed frame, and backpressure outcome. Every schema invariant has at least one accepted and rejected fixture.
- Semantic fixture validation supplements structural JSON Schema checks. It verifies protocol range ordering, capability intersection, finite/open-ended exclusivity, nullable state fields, result-command correlation, event sequencing and payload combinations, Recovery capability matrices, UUID and timestamp form, archive path uniqueness, hash integrity, default references, unique contribution identities, and completion-marker constraints.
- Pure unit tests use deterministic fake monotonic and wall clocks for generated state-machine transition sequences, duration parsing, Config resolution, rounding, deadline races, sleep ordering, wall-clock changes, midnight splitting, timezone retention, locale week grouping, streak behavior, compact and detailed formatting, repositories, and schema mappings.
- Real temporary SQLite databases are used only at the persistence platform boundary. They validate physical constraints and triggers, foreign keys, accepted-start recency, default fallback, transaction rollback, concurrent reads, date splitting, unique Phase segments, single completion markers, Clear History, backup creation and rotation, every supported migration, migration failures, newer schemas, corrupt data, Recovery Retry and Discard, Reset, and archive byte/hash correctness.
- Real Unix sockets and Agent processes are used only at the process and transport boundary. They validate private endpoint permissions, exclusive ownership, stale endpoint safety, framing and the one-mebibyte limit, negotiation, concurrent commands, response-loss retry, bounded follower queues, disconnect behavior, Agent auto-launch, repeated launch forwarding, and relaunch interruption notices.
- CLI subprocess and pseudo-terminal tests are used only where process streams, signals, and terminal behavior matter. They cover every command and exit code, standard-output and standard-error ownership, JSON and NDJSON parsing, non-TTY rejection, plain mode, wizard navigation, resize preservation, color and Unicode fallbacks, Control-C, detach, handled signals, disconnect, Agent startup timeout, final scrollback lines, and restoration of terminal modes and screens.
- Terminal rendering snapshots cover widths sixty, eighty, and one hundred twenty; all wizard steps; Running, Ready, Paused, and Recovery dashboards; validation, resize, and help; and Unicode/color plus ASCII/no-color modes. Rendering snapshots do not replace behavioral command/event assertions.
- XCUITest is used only at the native macOS UI boundary. It covers status-item and menu flows, adaptive controls, Custom Session and Welcome popovers, Settings tabs, Preset management, summary layout, confirmation scope, Recovery actions, notification routing, launch-at-login errors, keyboard focus order, VoiceOver labels, and non-color cues while isolating real user data and login registration.
- Artifact and release seams validate both architecture slices, deployment target, shared app and CLI version, bundle identity, nested-code and Hardened Runtime signatures, expected archive contents, SHA-256 evidence, cask syntax and metadata, completions, zap scope, dependency locks and licenses, clean rebuild output, and equivalence between direct and Homebrew downloads.
- Manual platform validation is reserved for boundaries automation cannot faithfully simulate: real sleep and wake including deadline races, notification allowed/denied/pending/disabled states and actions, sound, login registration, VoiceOver, Increase Contrast, Reduce Motion, light and dark appearances, Gatekeeper Open Anyway, clean-profile onboarding, Homebrew install/upgrade/uninstall/zap, direct archive installation, and supported hardware and operating-system combinations.
- Performance validation uses Release builds on otherwise idle supported Macs and records hardware, architecture, macOS, toolchain, configuration, and raw results. It measures ten-minute Idle and active CPU, one hundred local command requests with p50 and p95, twenty cold Agent starts, one hundred fake-clock plus twenty real-clock transition samples, and stalled-follower memory behavior.
- The release thresholds are no Idle timer polling and near-zero sustained CPU, investigation above one percent sustained active CPU, local command p95 below 200 milliseconds, every cold Start acknowledgment below three seconds, and awake transition p95 below 250 milliseconds.
- The non-destructive local validation gate consists of dependency resolution, strict formatting, schema and semantic fixture checks, unit tests, integration tests, CLI tests, UI tests, and development build. Packaging and release checks are separate because they create artifacts or exercise release-only conditions.
- Milestone one cannot pass without one Agent owner, direct non-interactive Start/Status/Stop, a minimal native countdown, protocol mismatch rejection, stale-socket safety, request deduplication, and demonstrated CLI/menu state parity. Terminal wizard and Follow restoration become mandatory at milestone two.
- Every implementation task records the exact validation command, environment, result, and evidence location. Missing required Apple Silicon, Intel, macOS 13, or current-supported-macOS evidence is a release blocker unless this specification is explicitly revised.

## Out of Scope

- Operating systems other than macOS are not supported.
- Cloud accounts, synchronization, shared teams, remote control, and server-hosted data are excluded.
- Active Session restoration after Agent crash, Agent restart, Mac restart, or upgrade is excluded.
- Detailed event history for every pause, resume, skip, interruption, and control action is excluded; only finalized Focus contributions and completed-Round markers are retained.
- Full settings parity in the CLI is excluded; Presets and global preferences are managed through native Settings in the first release.
- System-wide keyboard shortcuts and terminal mouse support are excluded.
- Recovery archive import, merge, automatic downgrade, and automatic database repair are excluded.
- In-app updates and self-updates are excluded.
- Apple Developer ID signing, notarization, Mac App Store distribution, and App Sandbox support are excluded from stable 1.0.
- Official Homebrew core or cask acceptance is not promised; distribution uses the project tap.
- Quarantine removal commands, global Gatekeeper disablement, silent Agent termination, and automatic data reset are prohibited rather than supported alternatives.
- Notarization remains intentional future work and is not a hidden stable-release gate.

## Further Notes

[README.md](README.md) is the feature planning index and [ROADMAP.md](ROADMAP.md) is the canonical ticket topology. [FEATURES.md](FEATURES.md) preserves the detailed grilling and design context behind this formal ready-for-agent specification. Implementers should use this specification for scope and traceability, then consult the feature context and companion contracts for resolved detail.

The domain terms Agent, CLI, Preset, Session Configuration, Session, Phase, Round, Transition, Ready, Idle, Recovery, and Summary Record are normative. In particular, Agent must not be called a background CLI, Round must not be replaced by the ambiguous term cycle, and Session and Phase must remain distinct when discussing timing or control.

The accepted architecture, native Swift and local IPC, transactional persistence and monotonic timing, and project-tap release decisions are binding. Companion command, protocol, data, schema-semantic, database, terminal UI, native UI, release, validation, SQL, and JSON-schema contracts provide the detailed normative constraints summarized here. If an implementation choice conflicts with those accepted decisions, the conflict requires an explicit specification or ADR revision before implementation proceeds.

All four delivery milestones retain the full stable 1.0 scope. Milestones sequence risk: first authority and IPC, then interactive and native behavior, then summaries and Recovery, then universal release and distribution. Preview testing is limited to maintainers and invited technical users, while stable release still carries the documented unnotarized Gatekeeper friction.

No product, protocol, storage, Recovery, terminal UI, native layout, release, or validation question remains open. Implementation-local type decomposition, script organization, and task sequencing may vary only where they preserve the observable decisions and tests in this specification.
