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
        let response = PublicResponse.success(snapshot: await agent.snapshot())

        let data = try JSONEncoder().encode(response)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["schema_version"] as? Int, 1)
        XCTAssertEqual(object["success"] as? Bool, true)
        XCTAssertTrue(object["error"] is NSNull)
        let snapshot = try XCTUnwrap(object["snapshot"] as? [String: Any])
        XCTAssertEqual(snapshot["agent_state"] as? String, "idle")
        XCTAssertTrue(snapshot["session"] is NSNull)
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