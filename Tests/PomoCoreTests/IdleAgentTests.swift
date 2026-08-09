import PomoCore
import XCTest

final class IdleAgentTests: XCTestCase {
    func testLifecycleStoreConsumesUnexpectedTerminationOnce() {
        let suiteName = "pomo-lifecycle-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = AgentLifecycleStore(defaults: defaults)
        let instanceID = UUID()

        store.markRunning(instanceID: instanceID, hasActiveSession: true)

        XCTAssertEqual(
            store.consumeUnexpectedTermination(),
            AgentLifecycleMarker(
                priorAgentInstanceID: instanceID,
                hadActiveSession: true,
                exitedCleanly: false))
        XCTAssertNil(store.consumeUnexpectedTermination())
    }

    func testLifecycleStoreRecordsCleanExitWithoutInterruptionNotice() {
        let suiteName = "pomo-lifecycle-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = AgentLifecycleStore(defaults: defaults)
        let instanceID = UUID()

        store.markRunning(instanceID: instanceID, hasActiveSession: true)
        store.markCleanExit(instanceID: instanceID, hasActiveSession: false)

        XCTAssertNil(store.consumeUnexpectedTermination())
        XCTAssertEqual(
            store.marker,
            AgentLifecycleMarker(
                priorAgentInstanceID: instanceID,
                hadActiveSession: false,
                exitedCleanly: true))
    }

    func testIdleAgentExposesSnapshotWithoutSessionData() async {
        let agent = PomoAgentCore(productVersion: "0.1.0")

        let snapshot = await agent.snapshot()

        XCTAssertTrue(snapshot.agentRunning)
        XCTAssertEqual(snapshot.agentState, .idle)
        XCTAssertEqual(snapshot.revision, 0)
        XCTAssertNil(snapshot.session)
        XCTAssertNil(snapshot.recovery)
        XCTAssertNotNil(snapshot.agentInstanceID)
        XCTAssertFalse(snapshot.agentInstanceID?.uuidString.isEmpty ?? true)
    }

    func testPublicIdleStatusUsesOneSchemaVersionedResponse() async throws {
        let agent = PomoAgentCore(productVersion: "0.1.0")
        let agentSnapshot = await agent.snapshot()
        let response = PublicResponse.success(snapshot: agentSnapshot)

        let data = try JSONEncoder().encode(response)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["schema_version"] as? Int, 1)
        XCTAssertEqual(object["command"] as? String, "status")
        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertTrue(object["error"] is NSNull)
        let snapshot = try XCTUnwrap(object["data"] as? [String: Any])
        XCTAssertEqual(
            Set(snapshot.keys),
            [
                "agent_running", "agent_instance_id", "agent_state", "state_revision",
                "session_id", "session_state", "phase_id", "phase_type", "source_preset_name",
                "configuration", "completed_rounds", "configured_duration_seconds",
                "remaining_seconds",
                "session_started_at", "phase_started_at", "expected_transition_at", "recovery",
            ]
        )
        XCTAssertEqual(snapshot["agent_state"] as? String, "idle")
        XCTAssertEqual(snapshot["state_revision"] as? Int, 0)
        XCTAssertEqual(
            snapshot["agent_instance_id"] as? String,
            try XCTUnwrap(agentSnapshot.agentInstanceID).uuidString.lowercased()
        )
        XCTAssertTrue(snapshot["session_id"] is NSNull)
        XCTAssertTrue(snapshot["session_state"] is NSNull)
        XCTAssertTrue(snapshot["phase_id"] is NSNull)
        XCTAssertTrue(snapshot["phase_type"] is NSNull)
        XCTAssertTrue(snapshot["source_preset_name"] is NSNull)
        XCTAssertTrue(snapshot["configuration"] is NSNull)
        XCTAssertTrue(snapshot["completed_rounds"] is NSNull)
        XCTAssertTrue(snapshot["configured_duration_seconds"] is NSNull)
        XCTAssertTrue(snapshot["remaining_seconds"] is NSNull)
        XCTAssertTrue(snapshot["session_started_at"] is NSNull)
        XCTAssertTrue(snapshot["phase_started_at"] is NSNull)
        XCTAssertTrue(snapshot["expected_transition_at"] is NSNull)
        XCTAssertTrue(snapshot["recovery"] is NSNull)
    }

    func testNotRunningStatusIsSuccessfulAndHasNoSnapshot() throws {
        let response = PublicResponse.agentNotRunning()

        let data = try JSONEncoder().encode(response)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["schema_version"] as? Int, 1)
        XCTAssertEqual(object["command"] as? String, "status")
        XCTAssertEqual(object["ok"] as? Bool, true)
        let snapshot = try XCTUnwrap(object["data"] as? [String: Any])
        XCTAssertEqual(snapshot["agent_running"] as? Bool, false)
        XCTAssertEqual(snapshot["agent_state"] as? String, "not_running")
        XCTAssertTrue(snapshot["agent_instance_id"] is NSNull)
        XCTAssertTrue(object["error"] is NSNull)
    }
}
