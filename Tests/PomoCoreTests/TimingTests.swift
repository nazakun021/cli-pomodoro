import Foundation
import PomoCore
import XCTest

final class TimingTests: XCTestCase {
    func testRunningFocusUsesMonotonicTimeWhenWallClockChanges() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)

        _ = try await agent.startClassic()
        clock.advance(monotonicBy: 2, wallBy: 3_600)

        let snapshot = await agent.snapshot()

        XCTAssertEqual(snapshot.remainingSeconds, 1_498)
    }

    func testSleepBeforeDeadlinePausesWithPositiveRemainingTime() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.startClassic()
        clock.advance(monotonicBy: 10, wallBy: 10)

        let sleeping = await agent.handleSleep()
        clock.advance(monotonicBy: 3_600, wallBy: 3_600)
        let afterWake = await agent.snapshot()

        XCTAssertEqual(sleeping.sessionState, .paused)
        XCTAssertEqual(sleeping.remainingSeconds, 1_490)
        XCTAssertEqual(afterWake.remainingSeconds, sleeping.remainingSeconds)
        XCTAssertNil(afterWake.expectedTransitionAt)
    }

    func testDeadlineReachedBeforeSleepTransitionsBeforePausing() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.startClassic()
        clock.advance(monotonicBy: 1_500, wallBy: 1_500)

        let snapshot = await agent.handleSleep()

        XCTAssertEqual(snapshot.phaseType, .shortBreak)
        XCTAssertEqual(snapshot.sessionState, .running)
        XCTAssertEqual(snapshot.completedRounds, 1)
        XCTAssertEqual(snapshot.remainingSeconds, 300)
    }

    func testPauseAndResumeApplyToRunningBreaks() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.startClassic()
        clock.advance(monotonicBy: 1_500, wallBy: 1_500)
        _ = await agent.handleSleep()
        clock.advance(monotonicBy: 10, wallBy: 10)

        let paused = try await agent.pauseSession()
        let resumed = try await agent.resumeSession()

        XCTAssertEqual(paused.phaseType, .shortBreak)
        XCTAssertEqual(paused.sessionState, .paused)
        XCTAssertEqual(paused.remainingSeconds, 290)
        XCTAssertEqual(resumed.phaseType, .shortBreak)
        XCTAssertEqual(resumed.sessionState, .running)
    }

    func testSleepDeadlineHonorsFiniteSessionBoundary() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.startClassic()

        for completedRound in 1...4 {
            clock.advance(monotonicBy: 1_500, wallBy: 1_500)
            let afterFocus = await agent.handleSleep()

            if completedRound == 4 {
                XCTAssertEqual(afterFocus.agentState, .idle)
                return
            }

            XCTAssertEqual(afterFocus.phaseType, .shortBreak)
            XCTAssertEqual(afterFocus.sessionState, .running)
            clock.advance(monotonicBy: 300, wallBy: 300)
            let afterBreak = await agent.handleSleep()
            XCTAssertEqual(afterBreak.phaseType, .focus)
            XCTAssertEqual(afterBreak.sessionState, .ready)
            _ = try await agent.resumeSession()
        }
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