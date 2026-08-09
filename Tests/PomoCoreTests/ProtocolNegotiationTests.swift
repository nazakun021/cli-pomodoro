import PomoCore
import XCTest

final class ProtocolNegotiationTests: XCTestCase {
    func testNegotiationSelectsHighestSharedMinorAndCapabilityIntersection() throws {
        let agent = ProtocolRange(major: 1, minimumMinor: 0, maximumMinor: 3)
        let client = ProtocolRange(major: 1, minimumMinor: 1, maximumMinor: 5)

        let result = try ProtocolNegotiator.negotiate(
            agent: agent,
            client: client,
            agentCapabilities: ["status", "follow"],
            clientCapabilities: ["status", "custom"]
        )

        XCTAssertEqual(result.version, ProtocolVersion(major: 1, minor: 3))
        XCTAssertEqual(result.capabilities, ["status"])
    }

    func testNegotiationRejectsDifferentProtocolMajor() {
        XCTAssertThrowsError(
            try ProtocolNegotiator.negotiate(
                agent: ProtocolRange(major: 1, minimumMinor: 0, maximumMinor: 0),
                client: ProtocolRange(major: 2, minimumMinor: 0, maximumMinor: 0),
                agentCapabilities: [],
                clientCapabilities: []
            )
        ) { error in
            XCTAssertEqual(error as? ProtocolNegotiationError, .majorMismatch)
        }
    }
}
