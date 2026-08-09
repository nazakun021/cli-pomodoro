import PomoCore
import XCTest

final class FrameCodecTests: XCTestCase {
    func testFrameRoundTripsUTF8JSONPayload() throws {
        let payload = Data("{\"type\":\"hello\"}".utf8)

        let frame = try FrameCodec.encode(payload)

        XCTAssertEqual(try FrameCodec.decode(frame), payload)
    }

    func testFrameRejectsOversizedPayload() {
        XCTAssertThrowsError(
            try FrameCodec.encode(Data(repeating: 0, count: FrameCodec.maximumPayloadLength + 1))
        ) { error in
            XCTAssertEqual(error as? FrameCodecError, .oversizedPayload)
        }
    }
}
