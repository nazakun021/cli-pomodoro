import PomoCore
import XCTest

final class DurationParserTests: XCTestCase {
    func testParsesComposableIntegerUnits() throws {
        XCTAssertEqual(try DurationParser.parse("1h30m"), 5_400)
        XCTAssertEqual(try DurationParser.parse("90s"), 90)
    }

    func testRejectsInvalidAndOutOfRangeDurations() {
        for value in ["0s", "-1m", "1.5m", "25", "1d", "25h"] {
            XCTAssertThrowsError(try DurationParser.parse(value))
        }
    }
}
