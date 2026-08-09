import Foundation
import PomoCore
import XCTest

final class UnixSocketTests: XCTestCase {
    func testStatusOverSocketReturnsReachableIdleSnapshot() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }

        let response = try await LocalAgentClient(path: path).status()

        XCTAssertTrue(response.success)
        XCTAssertTrue(response.agentRunning)
        XCTAssertEqual(response.snapshot?.agentState, .idle)
        XCTAssertEqual(response.snapshot?.revision, 0)
    }

    func testSecondServerCannotReplaceLiveEndpoint() throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }

        XCTAssertThrowsError(try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0")))
    }
}