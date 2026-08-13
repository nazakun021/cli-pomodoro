# ADR-0005: Notify When Focus Is Ready After a Break

Status: Accepted

## Context

When a Break Phase completes and automatic Focus start is disabled, the next Focus Phase enters Ready. The Agent already owns this state and the menu already exposes a Start action, but a user may not notice the status-item change while working in another app.

Opening the status-item menu automatically would steal attention, can be disruptive while the user is typing or presenting, and is not necessary to make the state actionable. A modal alert would have the same interruption problem and would block unrelated work.

## Decision

- Treat this as the next Focus Phase in the current Session, not a new Session.
- Deliver one macOS User Notification for each natural Break-to-Focus Transition that leaves Focus Ready.
- Use the notification body: `Break complete. Focus round N is ready.`
- Offer the existing `Start Next Phase` notification action. Activating it starts the matching Ready Focus Phase only when its Session and Phase identifiers still match.
- Dismissal leaves the Focus Phase Ready and available from the menu-bar menu.
- Do not automatically open the status-item menu.
- Do not repeat the notification while the same Focus Phase remains Ready.
- Do not issue this notification when automatic Focus start is enabled.
- Keep the menu-bar representation as the persistent fallback: Focus Ready, full duration, and Start as the primary menu action.
- When notification capability is unavailable or denied, retain the sound and missed-alert/menu fallback behavior without queuing a stale notification.

## Consequences

### Positive

- The prompt is discoverable without hijacking the user's current app.
- The action matches the existing Agent state model and can be handled safely through the existing phase identifier check.
- Users can defer the decision without losing the Session or changing timing.
- Notification delivery remains capability-gated for signed and ad-hoc builds.

### Negative

- Users who dismiss notifications must open the menu to start Focus.
- Notification Center settings and macOS focus modes can suppress the prompt, so the menu and sound remain necessary fallbacks.
- The current snapshot does not identify whether a Break-to-Focus Transition was natural or caused by Skip; notification eligibility must remain explicit if that distinction is added later.

## Alternatives considered

### Automatically open the status-item menu

Rejected because it steals attention and makes a background status item behave like a modal surface.

### Modal NSAlert

Rejected because it blocks the user's active application and is inconsistent with native background completion feedback.

### Start a new Session

Rejected because the Agent already has a Ready Focus Phase in the current Session; creating another Session would violate the one-Session model and distort Round accounting.
