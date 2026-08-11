import Foundation
import PomoCore
import XCTest

final class LifecycleTests: XCTestCase {
    func testUnexpectedTerminationMarkerIsConsumedOnce() {
        let suiteName = "pomo-lifecycle-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = AgentLifecycleStore(defaults: defaults)
        let instanceID = UUID()

        store.markRunning(instanceID: instanceID, hasActiveSession: true)

        let marker = store.consumeUnexpectedTermination()
        XCTAssertEqual(
            marker,
            AgentLifecycleMarker(
                priorAgentInstanceID: instanceID,
                hadActiveSession: true,
                exitedCleanly: false))
        XCTAssertNil(store.consumeUnexpectedTermination())
    }

    func testCleanExitDoesNotCreateInterruptionNotice() {
        let suiteName = "pomo-lifecycle-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = AgentLifecycleStore(defaults: defaults)
        let instanceID = UUID()

        store.markCleanExit(instanceID: instanceID, hasActiveSession: true)

        XCTAssertNil(store.consumeUnexpectedTermination())
        XCTAssertEqual(
            store.marker,
            AgentLifecycleMarker(
                priorAgentInstanceID: instanceID,
                hadActiveSession: true,
                exitedCleanly: true))
    }

    func testRelaunchConsumesCrashMarkerBeforeMarkingNewAgentRunning() {
        let suiteName = "pomo-lifecycle-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = AgentLifecycleStore(defaults: defaults)
        let priorInstanceID = UUID()
        let newInstanceID = UUID()

        store.markRunning(instanceID: priorInstanceID, hasActiveSession: true)
        let priorInterruption = store.consumeUnexpectedTermination()
        store.markRunning(instanceID: newInstanceID, hasActiveSession: false)

        XCTAssertEqual(
            priorInterruption,
            AgentLifecycleMarker(
                priorAgentInstanceID: priorInstanceID,
                hadActiveSession: true,
                exitedCleanly: false))
        XCTAssertEqual(store.marker?.priorAgentInstanceID, newInstanceID)
        XCTAssertTrue(store.marker?.exitedCleanly == false)
    }
}
