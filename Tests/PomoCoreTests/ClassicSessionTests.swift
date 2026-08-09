import PomoCore
import XCTest

final class ClassicSessionTests: XCTestCase {
    func testStartClassicCreatesRunningFocusWithCompleteConfiguration() async throws {
        let agent = PomoAgentCore(productVersion: "0.1.0")

        let snapshot = try await agent.startClassic()

        XCTAssertEqual(snapshot.agentState, .session)
        XCTAssertEqual(snapshot.sessionState, .running)
        XCTAssertEqual(snapshot.phaseType, .focus)
        XCTAssertEqual(snapshot.configuration, .classic)
        XCTAssertEqual(snapshot.completedRounds, 0)
        XCTAssertEqual(snapshot.remainingSeconds, 1_500)
        XCTAssertEqual(snapshot.revision, 1)
    }

    func testStopClassicEndsTheSessionAndReturnsIdle() async throws {
        let agent = PomoAgentCore(productVersion: "0.1.0")
        _ = try await agent.startClassic()

        let snapshot = try await agent.stopSession()

        XCTAssertEqual(snapshot.agentState, .idle)
        XCTAssertNil(snapshot.sessionID)
        XCTAssertEqual(snapshot.revision, 2)
    }
}
