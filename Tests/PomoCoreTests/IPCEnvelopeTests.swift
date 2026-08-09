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

    func testStopEndsSessionAndLaterStatusIsIdle() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }
        let client = LocalAgentClient(path: path)
        _ = try await client.startClassicResponse(requestID: UUID())

        let stopped = try await client.stopResponse(requestID: UUID())
        let observed = try await client.statusResponse(requestID: UUID())

        XCTAssertEqual(stopped.result?.agentState, .idle)
        XCTAssertEqual(observed.result?.agentState, .idle)
        XCTAssertEqual(observed.result?.revision, 2)
    }

    func testDuplicateStartRequestReturnsOriginalOutcome() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }
        let client = LocalAgentClient(path: path)
        let requestID = UUID()

        let first = try await client.startClassicResponse(requestID: requestID)
        let duplicate = try await client.startClassicResponse(requestID: requestID)

        XCTAssertEqual(duplicate.result?.sessionID, first.result?.sessionID)
        XCTAssertEqual(duplicate.result?.revision, first.result?.revision)
    }

    func testSecondStartIsRejectedWithoutDisturbingActiveSession() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }
        let client = LocalAgentClient(path: path)
        let first = try await client.startClassicResponse(requestID: UUID())

        let rejected = try await client.startClassicResponse(requestID: UUID())
        let observed = try await client.statusResponse(requestID: UUID())

        XCTAssertFalse(rejected.ok)
        XCTAssertEqual(rejected.error?.code, "invalid_state")
        XCTAssertEqual(rejected.error?.exitCode, 3)
        XCTAssertTrue(rejected.error?.message.contains("Current state: session") == true)
        XCTAssertTrue(rejected.error?.message.contains("Valid next actions: stop") == true)
        XCTAssertEqual(observed.result?.sessionID, first.result?.sessionID)
        XCTAssertEqual(observed.result?.revision, first.result?.revision)
    }

    func testReplacementStartCreatesOneNewSession() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }
        let client = LocalAgentClient(path: path)
        let first = try await client.startClassicResponse(requestID: UUID())

        let replacement = try await client.startClassicResponse(requestID: UUID(), replace: true)

        XCTAssertTrue(replacement.ok)
        XCTAssertNotEqual(replacement.result?.sessionID, first.result?.sessionID)
        XCTAssertEqual(replacement.result?.revision, 2)
    }

    func testExpiredFutureAndWrongAgentMutationsAreRejectedWithoutStateChange() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }
        let client = LocalAgentClient(path: path)

        let expired = try await client.startClassicResponse(
            requestID: UUID(), issuedAt: utcTimestamp(Date().addingTimeInterval(-301)))
        let future = try await client.startClassicResponse(
            requestID: UUID(), issuedAt: utcTimestamp(Date().addingTimeInterval(31)))
        let wrongAgent = try await client.startClassicResponse(
            requestID: UUID(), agentInstanceID: UUID())
        let observed = try await client.statusResponse(requestID: UUID())

        XCTAssertEqual(expired.error?.code, "invalid_request")
        XCTAssertEqual(future.error?.code, "invalid_request")
        XCTAssertEqual(wrongAgent.error?.code, "invalid_request")
        XCTAssertEqual(observed.result?.agentState, .idle)
        XCTAssertEqual(observed.result?.revision, 0)
    }

    func testDuplicateStopReturnsCachedIdleSnapshotWithoutApplyingTwice() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }
        let client = LocalAgentClient(path: path)
        _ = try await client.startClassicResponse(requestID: UUID())
        let requestID = UUID()

        let first = try await client.stopResponse(requestID: requestID)
        let duplicate = try await client.stopResponse(requestID: requestID)

        XCTAssertTrue(first.ok)
        XCTAssertEqual(duplicate.result?.revision, first.result?.revision)
        XCTAssertEqual(duplicate.result?.agentState, .idle)
    }
}

private func utcTimestamp(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}
