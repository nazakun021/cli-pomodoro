import XCTest

@testable import PomoAgentKit

final class NotificationCapabilityTests: XCTestCase {
    func testReadyFocusPromptRequiresACompletedBreakAndManualStart() {
        XCTAssertTrue(
            shouldPromptForReadyFocus(
                previousPhase: .shortBreak,
                currentPhase: .focus,
                currentAgentState: .session,
                currentSessionState: .ready,
                autoStartFocus: false))
        XCTAssertFalse(
            shouldPromptForReadyFocus(
                previousPhase: .longBreak,
                currentPhase: .focus,
                currentAgentState: .session,
                currentSessionState: .running,
                autoStartFocus: true))
        XCTAssertFalse(
            shouldPromptForReadyFocus(
                previousPhase: .focus,
                currentPhase: .shortBreak,
                currentAgentState: .session,
                currentSessionState: .ready,
                autoStartFocus: false))
    }

    func testSystemNotificationsRequireBundleAndTeamIdentifiers() {
        XCTAssertFalse(
            systemNotificationsAvailable(bundleIdentifier: nil, teamIdentifier: "TEAM"))
        XCTAssertFalse(
            systemNotificationsAvailable(
                bundleIdentifier: "com.nazakun.pomo",
                teamIdentifier: nil))
        XCTAssertTrue(
            systemNotificationsAvailable(
                bundleIdentifier: "com.nazakun.pomo",
                teamIdentifier: "TEAM"))
    }
}
