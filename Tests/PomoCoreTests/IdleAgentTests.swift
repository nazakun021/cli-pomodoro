import PomoCore
import XCTest

final class IdleAgentTests: XCTestCase {
    func testIdleAgentExposesSnapshotWithoutSessionData() async {
        let agent = PomoAgentCore(productVersion: "0.1.0")

        let snapshot = await agent.snapshot()

        XCTAssertTrue(snapshot.agentRunning)
        XCTAssertEqual(snapshot.agentState, .idle)
        XCTAssertEqual(snapshot.revision, 0)
        XCTAssertNil(snapshot.session)
        XCTAssertNil(snapshot.recovery)
        XCTAssertFalse(snapshot.agentInstanceID.uuidString.isEmpty)
    }

    func testPublicIdleStatusUsesOneSchemaVersionedResponse() async throws {
        let agent = PomoAgentCore(productVersion: "0.1.0")
        let agentSnapshot = await agent.snapshot()
        let response = PublicResponse.success(snapshot: agentSnapshot)

        let data = try JSONEncoder().encode(response)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["schema_version"] as? Int, 1)
        XCTAssertEqual(object["success"] as? Bool, true)
        XCTAssertTrue(object["error"] is NSNull)
        let snapshot = try XCTUnwrap(object["snapshot"] as? [String: Any])
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
            agentSnapshot.agentInstanceID.uuidString.lowercased()
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
        XCTAssertEqual(object["success"] as? Bool, true)
        XCTAssertEqual(object["agent_running"] as? Bool, false)
        XCTAssertTrue(object["snapshot"] is NSNull)
        XCTAssertTrue(object["error"] is NSNull)
    }
}
