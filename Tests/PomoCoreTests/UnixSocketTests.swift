import Darwin
import Foundation
import PomoCore
import XCTest

final class UnixSocketTests: XCTestCase {
    func testPresetDiscoveryReturnsDefaultAndNamedPresets() async throws {
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-presets-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let store = try PresetStore(databaseURL: databaseURL)
        let writing = try store.create(name: "Writing", configuration: .classic)
        try store.selectDefault(id: writing.id)
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(
            path: path, agent: PomoAgentCore(productVersion: "0.1.0", presetStore: store))
        defer { server.stop() }

        let discovery = try await LocalAgentClient(path: path).presetDiscovery()

        XCTAssertEqual(discovery.defaultPreset, writing)
        XCTAssertEqual(discovery.presets, [.classic, writing])
    }

    func testFollowReceivesInitialSnapshotEventAfterAcknowledgement() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }

        let event = try await LocalAgentClient(path: path).followInitialEvent()

        XCTAssertEqual(event.sequence, 0)
        XCTAssertEqual(event.kind, .initialSnapshot)
        XCTAssertEqual(event.snapshot?.agentState, .idle)
    }

    func testFollowStreamReceivesLaterSessionSnapshot() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let agent = PomoAgentCore(productVersion: "0.1.0")
        let server = try LocalAgentServer(path: path, agent: agent)
        defer { server.stop() }

        let events = try await LocalAgentClient(path: path).followEvents()
        var iterator = events.makeAsyncIterator()
        let initial = try await iterator.next()
        XCTAssertEqual(initial?.sequence, 0)
        _ = try await LocalAgentClient(path: path).startClassic()

        let update = try await iterator.next()
        XCTAssertEqual(update?.kind, .transition)
        XCTAssertEqual(update?.snapshot?.agentState, .session)
    }

    func testStatusOverSocketReturnsReachableIdleSnapshot() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }

        let response = try await LocalAgentClient(path: path).status()

        XCTAssertTrue(response.ok)
        XCTAssertTrue(response.data?.agentRunning == true)
        XCTAssertEqual(response.data?.agentState, .idle)
        XCTAssertEqual(response.data?.revision, 0)
    }

    func testSecondServerCannotReplaceLiveEndpoint() throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }

        XCTAssertThrowsError(
            try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0")))
    }

    func testClientWithDifferentMajorIsRejectedBeforeStatus() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }

        await XCTAssertThrowsErrorAsync(
            try await LocalAgentClient(
                path: path,
                supportedProtocol: ProtocolRange(major: 2, minimumMinor: 0, maximumMinor: 0)
            ).status()
        ) { error in
            XCTAssertEqual(error as? LocalAgentTransportError, .protocolMismatch)
        }
    }

    func testServerReclaimsOwnedStaleSocketAfterAcquiringLock() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString).sock").path
        let staleSocket = try bindUnlistenedSocket(at: path)
        Darwin.close(staleSocket)

        let server = try LocalAgentServer(path: path, agent: PomoAgentCore(productVersion: "0.1.0"))
        defer { server.stop() }

        let response = try await LocalAgentClient(path: path).status()
        XCTAssertTrue(response.data?.agentRunning == true)
    }
}

private func bindUnlistenedSocket(at path: String) throws -> Int32 {
    let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
    guard descriptor >= 0 else { throw POSIXError(.ENFILE) }
    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    let bytes = Array(path.utf8) + [0]
    withUnsafeMutableBytes(of: &address.sun_path) { destination in
        bytes.withUnsafeBytes { source in destination.copyBytes(from: source) }
    }
    let result = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            Darwin.bind(descriptor, $0, socklen_t(MemoryLayout<sa_family_t>.size + bytes.count))
        }
    }
    guard result == 0 else {
        Darwin.close(descriptor)
        throw POSIXError(.EADDRINUSE)
    }
    return descriptor
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ errorHandler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail("Expected an error")
    } catch {
        errorHandler(error)
    }
}
