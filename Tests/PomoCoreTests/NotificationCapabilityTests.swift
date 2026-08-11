import XCTest

@testable import PomoAgentKit

final class NotificationCapabilityTests: XCTestCase {
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
