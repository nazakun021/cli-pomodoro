import Foundation
import PomoCore
import XCTest

final class SummaryTests: XCTestCase {
    func testSummaryStorePersistsAndDeduplicatesFocusContribution() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-summary-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SummaryStore(fileURL: url)
        let phaseID = UUID()
        let contribution = FocusContribution(
            phaseID: phaseID, date: "2026-08-10", elapsedMilliseconds: 90_001,
            completedRound: true)

        try store.record(contribution)
        try store.record(contribution)

        XCTAssertEqual(
            store.summary(for: "2026-08-10"),
            DailySummary(focusMilliseconds: 90_001, completedRounds: 1))
        let reloaded = try SummaryStore(fileURL: url)
        XCTAssertEqual(
            reloaded.summary(for: "2026-08-10"),
            DailySummary(focusMilliseconds: 90_001, completedRounds: 1))
    }

    func testSummaryStoreKeepsSplitContributionsForOnePhase() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-summary-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SummaryStore(fileURL: url)
        let phaseID = UUID()

        try store.record(
            FocusContribution(
                phaseID: phaseID, date: "2026-08-10", elapsedMilliseconds: 1_000,
                completedRound: false))
        try store.record(
            FocusContribution(
                phaseID: phaseID, date: "2026-08-11", elapsedMilliseconds: 2_000,
                completedRound: true))

        XCTAssertEqual(store.summary(for: "2026-08-10").focusMilliseconds, 1_000)
        XCTAssertEqual(
            store.summary(for: "2026-08-11"),
            DailySummary(focusMilliseconds: 2_000, completedRounds: 1))
    }
}
