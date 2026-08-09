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

    func testDecodeRejectsZeroLengthTruncatedAndMismatchedFrames() {
        let zeroLength = Data([0, 0, 0, 0])
        let truncated = Data([0, 0, 0])
        let mismatchedLength = Data([0, 0, 0, 2, 0x7B])

        XCTAssertThrowsError(try FrameCodec.decode(zeroLength)) { error in
            XCTAssertEqual(error as? FrameCodecError, .emptyPayload)
        }
        XCTAssertThrowsError(try FrameCodec.decode(truncated)) { error in
            XCTAssertEqual(error as? FrameCodecError, .truncatedFrame)
        }
        XCTAssertThrowsError(try FrameCodec.decode(mismatchedLength)) { error in
            XCTAssertEqual(error as? FrameCodecError, .lengthMismatch)
        }
    }
}
