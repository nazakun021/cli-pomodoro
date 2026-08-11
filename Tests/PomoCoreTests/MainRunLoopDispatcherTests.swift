import XCTest

@testable import PomoAgentKit

final class MainRunLoopDispatcherTests: XCTestCase {
    @MainActor
    func testDispatcherPreservesPendingActionsInOrder() {
        let dispatcher = MainRunLoopDispatcher()
        let completed = expectation(description: "Both pending actions completed")
        var values: [Int] = []

        dispatcher.dispatch {
            values.append(1)
        }
        dispatcher.dispatch {
            values.append(2)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 1)
        XCTAssertEqual(values, [1, 2])
    }
}
