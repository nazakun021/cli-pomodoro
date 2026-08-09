import Foundation
import PomoCore
import XCTest

final class MidnightAccountingTests: XCTestCase {
    func testFocusCompletionSplitsContributionAcrossLocalMidnight() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-midnight-accounting-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SummaryStore(fileURL: url)
        let calendar = Calendar.current
        let start = calendar.date(
            byAdding: .second, value: -1, to: calendar.startOfDay(for: Date()))!
        let clock = MidnightTestClock(start: start)
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock, summaryStore: store)
        let configuration = try SessionConfiguration(
            focusSeconds: 3, shortBreakSeconds: 1, longBreakSeconds: 1,
            longBreakEvery: 4, openEnded: false, targetRounds: 1,
            autoStartFocus: true, autoStartBreaks: true)

        _ = try await agent.start(configuration: configuration)
        clock.advance(monotonicBy: 3, wallBy: 3)
        _ = await agent.advanceIfDue()

        XCTAssertEqual(store.summary(for: dateString(start)), DailySummary(focusMilliseconds: 1_000, completedRounds: 0))
        XCTAssertEqual(store.summary(for: dateString(start.addingTimeInterval(3))), DailySummary(focusMilliseconds: 2_000, completedRounds: 1))
    }
}

private func dateString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

private final class MidnightTestClock: @unchecked Sendable {
    private var monotonicNow: TimeInterval = 0
    private var wallNow: Date

    init(start: Date) { wallNow = start }

    var clock: AgentClock {
        AgentClock(monotonicNow: { self.monotonicNow }, wallNow: { self.wallNow })
    }

    func advance(monotonicBy monotonic: TimeInterval, wallBy wall: TimeInterval) {
        monotonicNow += monotonic
        wallNow.addTimeInterval(wall)
    }
}
