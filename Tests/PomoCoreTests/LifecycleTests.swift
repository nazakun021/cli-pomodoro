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
}
