import Darwin
import Foundation
import PomoCore
import XCTest

final class RuntimeEndpointTests: XCTestCase {
    func testPrepareCreatesOwnerOnlyPomoDirectoryAndVersionedSocketPath() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-runtime-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let socketPath = try RuntimeEndpoint.prepare(in: root)
        var metadata = stat()

        XCTAssertEqual(stat(root.appendingPathComponent("pomo").path, &metadata), 0)
        XCTAssertEqual(metadata.st_mode & 0o777, 0o700)
        XCTAssertEqual(socketPath, root.appendingPathComponent("pomo/agent-v1.sock").path)
    }
}