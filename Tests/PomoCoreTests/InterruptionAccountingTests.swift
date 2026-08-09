import Foundation
import PomoCore
import XCTest

final class InterruptionAccountingTests: XCTestCase {
    func testStoppingFocusRecordsElapsedTimeWithoutCompletedRound() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-stop-accounting-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SummaryStore(fileURL: url)
        let clock = InterruptionTestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock, summaryStore: store)
        let configuration = try SessionConfiguration(
            focusSeconds: 10, shortBreakSeconds: 1, longBreakSeconds: 1,
            longBreakEvery: 4, openEnded: false, targetRounds: 1,
            autoStartFocus: true, autoStartBreaks: true)

        _ = try await agent.start(configuration: configuration)
        clock.advance(monotonicBy: 3, wallBy: 3)
        _ = try await agent.stopSession()

        XCTAssertEqual(
            store.summary(for: "1970-01-01"),
            DailySummary(focusMilliseconds: 3_000, completedRounds: 0))
    }

    func testSkippingFocusRecordsElapsedTimeWithoutCompletedRound() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-skip-accounting-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SummaryStore(fileURL: url)
        let clock = InterruptionTestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock, summaryStore: store)
        let configuration = try SessionConfiguration(
            focusSeconds: 10, shortBreakSeconds: 1, longBreakSeconds: 1,
            longBreakEvery: 4, openEnded: false, targetRounds: 1,
            autoStartFocus: true, autoStartBreaks: true)

        _ = try await agent.start(configuration: configuration)
        clock.advance(monotonicBy: 4, wallBy: 4)
        _ = try await agent.skipPhase()

        XCTAssertEqual(
            store.summary(for: "1970-01-01"),
            DailySummary(focusMilliseconds: 4_000, completedRounds: 0))
    }
}

private final class InterruptionTestClock: @unchecked Sendable {
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
