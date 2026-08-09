import Foundation
import PomoCore
import XCTest

final class IPCEnvelopeTests: XCTestCase {
    func testStatusResponseEchoesRequestIDAndNegotiatedProtocol() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }
        let requestID = UUID()

        let response = try await LocalAgentClient(path: path).statusResponse(requestID: requestID)

        XCTAssertTrue(response.ok)
        XCTAssertEqual(response.requestID, requestID)
        XCTAssertEqual(response.protocolVersion, ProtocolVersion(major: 1, minor: 0))
        XCTAssertEqual(response.result?.agentState, .idle)
        XCTAssertNil(response.error)
    }

    func testStartClassicIsObservableThroughLaterStatus() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }
        let client = LocalAgentClient(path: path)

        let started = try await client.startClassicResponse(requestID: UUID())
        let observed = try await client.statusResponse(requestID: UUID())

        XCTAssertEqual(started.result?.agentState, .session)
        XCTAssertEqual(started.result?.phaseType, .focus)
        XCTAssertEqual(observed.result?.sessionID, started.result?.sessionID)
        XCTAssertEqual(observed.result?.revision, started.result?.revision)
    }
}
