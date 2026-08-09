import PomoCore
import XCTest

final class SessionConfigurationTests: XCTestCase {
    func testFiniteConfigurationRequiresPositiveTargetRounds() {
        XCTAssertThrowsError(
            try SessionConfiguration(
                focusSeconds: 1_500,
                shortBreakSeconds: 300,
                longBreakSeconds: 900,
                longBreakEvery: 4,
                openEnded: false,
                targetRounds: 0,
                autoStartFocus: false,
                autoStartBreaks: true))
    }
}
