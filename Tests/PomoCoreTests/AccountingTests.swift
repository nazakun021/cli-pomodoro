import Foundation
import PomoCore
import XCTest

final class AccountingTests: XCTestCase {
    func testNaturalFocusCompletionRecordsDailySummary() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-accounting-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SummaryStore(fileURL: url)
        let clock = AccountingTestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock, summaryStore: store)
        let configuration = try SessionConfiguration(
            focusSeconds: 1, shortBreakSeconds: 1, longBreakSeconds: 1,
            longBreakEvery: 4, openEnded: false, targetRounds: 1,
            autoStartFocus: true, autoStartBreaks: true)

        _ = try await agent.start(configuration: configuration)
        clock.advance(monotonicBy: 1, wallBy: 1)
        _ = await agent.advanceIfDue()

        XCTAssertEqual(store.summary(for: "1970-01-01"), DailySummary(focusMilliseconds: 1_000, completedRounds: 1))
    }
}

private final class AccountingTestClock: @unchecked Sendable {
    private var monotonicNow: TimeInterval = 0
    private var wallNow = Date(timeIntervalSince1970: 0)

    var clock: AgentClock {
        AgentClock(monotonicNow: { self.monotonicNow }, wallNow: { self.wallNow })
    }

    func advance(monotonicBy monotonic: TimeInterval, wallBy wall: TimeInterval) {
        monotonicNow += monotonic
        wallNow.addTimeInterval(wall)
    }
}
