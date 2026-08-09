import Darwin
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
