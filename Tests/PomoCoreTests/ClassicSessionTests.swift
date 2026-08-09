import Foundation
import PomoCore
import XCTest

final class ClassicSessionTests: XCTestCase {
    func testStartClassicCreatesRunningFocusWithCompleteConfiguration() async throws {
        let agent = PomoAgentCore(productVersion: "0.1.0")

        let snapshot = try await agent.startClassic()

        XCTAssertEqual(snapshot.agentState, .session)
        XCTAssertEqual(snapshot.sessionState, .running)
        XCTAssertEqual(snapshot.phaseType, .focus)
        XCTAssertEqual(snapshot.configuration, .classic)
        XCTAssertEqual(snapshot.completedRounds, 0)
        XCTAssertEqual(snapshot.remainingSeconds, 1_500)
        XCTAssertNotNil(snapshot.phaseStartedAt)
        XCTAssertNotNil(snapshot.expectedTransitionAt)
        XCTAssertEqual(snapshot.revision, 1)
    }

    func testStopClassicEndsTheSessionAndReturnsIdle() async throws {
        let agent = PomoAgentCore(productVersion: "0.1.0")
        _ = try await agent.startClassic()

        let snapshot = try await agent.stopSession()

        XCTAssertEqual(snapshot.agentState, .idle)
        XCTAssertNil(snapshot.sessionID)
        XCTAssertEqual(snapshot.revision, 2)
    }

    func testStartUsesCompleteOpenEndedConfiguration() async throws {
        let configuration = try SessionConfiguration(
            focusSeconds: 60,
            shortBreakSeconds: 15,
            longBreakSeconds: 30,
            longBreakEvery: 2,
            openEnded: true,
            targetRounds: nil,
            autoStartFocus: false,
            autoStartBreaks: true)
        let agent = PomoAgentCore(productVersion: "0.1.0")

        let snapshot = try await agent.start(configuration: configuration)

        XCTAssertEqual(snapshot.configuration, configuration)
        XCTAssertEqual(snapshot.sessionState, .running)
        XCTAssertEqual(snapshot.phaseType, .focus)
        XCTAssertNil(snapshot.configuration?.targetRounds)
        XCTAssertEqual(snapshot.remainingSeconds, 60)
    }

    func testFiniteSessionEndsAfterItsFinalFocus() async throws {
        let clock = TestClock()
        let configuration = try SessionConfiguration(
            focusSeconds: 60,
            shortBreakSeconds: 15,
            longBreakSeconds: 30,
            longBreakEvery: 2,
            openEnded: false,
            targetRounds: 1,
            autoStartFocus: false,
            autoStartBreaks: true)
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.start(configuration: configuration)
        clock.advance(monotonicBy: 60, wallBy: 60)

        let snapshot = await agent.advanceIfDue()

        XCTAssertEqual(snapshot.agentState, .idle)
        XCTAssertNil(snapshot.sessionID)
    }
}

private final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var monotonicNow: TimeInterval = 0
    private var wallNow = Date(timeIntervalSince1970: 0)

    var clock: AgentClock {
        AgentClock(
            monotonicNow: { [weak self] in self?.monotonic() ?? 0 },
            wallNow: { [weak self] in self?.wall() ?? Date(timeIntervalSince1970: 0) }
        )
    }

    func advance(monotonicBy monotonicInterval: TimeInterval, wallBy wallInterval: TimeInterval) {
        lock.lock()
        monotonicNow += monotonicInterval
        wallNow.addTimeInterval(wallInterval)
        lock.unlock()
    }

    private func monotonic() -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return monotonicNow
    }

    private func wall() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return wallNow
    }
}
