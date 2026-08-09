import Foundation
import PomoCore
import XCTest

final class TimingTests: XCTestCase {
    func testAlertPreferencesDefaultToEnabledAndPersistOnboardingDismissal() {
        let defaults = UserDefaults(suiteName: "pomo-alert-test-\(UUID().uuidString)")!
        let store = AlertPreferencesStore(defaults: defaults)

        XCTAssertEqual(store.preferences, .default)
        XCTAssertFalse(store.hasCompletedOnboarding)

        store.preferences = AlertPreferences(notificationsEnabled: false, soundEnabled: true)
        store.hasCompletedOnboarding = true
        store.hasMissedAlert = true

        let reloaded = AlertPreferencesStore(defaults: defaults)
        XCTAssertEqual(reloaded.preferences.notificationsEnabled, false)
        XCTAssertEqual(reloaded.preferences.soundEnabled, true)
        XCTAssertTrue(reloaded.hasCompletedOnboarding)
        XCTAssertTrue(reloaded.hasMissedAlert)
    }

    func testFollowSnapshotsYieldsInitialAndStartedSession() async throws {
        let agent = PomoAgentCore(productVersion: "0.1.0")
        let stream = await agent.followSnapshots()
        var iterator = stream.makeAsyncIterator()

        let initial = await iterator.next()
        _ = try await agent.startClassic()
        let started = await iterator.next()

        XCTAssertEqual(initial?.agentState, .idle)
        XCTAssertEqual(started?.agentState, .session)
        XCTAssertEqual(started?.sessionState, .running)
    }

    func testRunningFocusUsesMonotonicTimeWhenWallClockChanges() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)

        _ = try await agent.startClassic()
        clock.advance(monotonicBy: 2, wallBy: 3_600)

        let snapshot = await agent.snapshot()

        XCTAssertEqual(snapshot.remainingSeconds, 1_498)
    }

    func testExpectedTransitionUsesExactMonotonicRemainder() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.startClassic()
        clock.advance(monotonicBy: 0.25, wallBy: 3_600)

        let snapshot = await agent.snapshot()

        XCTAssertEqual(snapshot.remainingSeconds, 1_500)
        XCTAssertEqual(
            try XCTUnwrap(snapshot.expectedTransitionAt),
            timestamp(Date(timeIntervalSince1970: 5_099.75)))
    }

    func testDisplayRoundsUpUntilTheDeadline() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.startClassic()

        clock.advance(monotonicBy: 0.001, wallBy: 0.001)
        let beforeBoundary = await agent.snapshot()
        clock.advance(monotonicBy: 1, wallBy: 1)
        let afterBoundary = await agent.snapshot()

        XCTAssertEqual(beforeBoundary.remainingSeconds, 1_500)
        XCTAssertEqual(afterBoundary.remainingSeconds, 1_499)
    }

    func testResumeRecalculatesExpectedTransitionFromCurrentWallTime() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.startClassic()
        clock.advance(monotonicBy: 0.25, wallBy: 10)
        let paused = try await agent.pauseSession()
        clock.advance(monotonicBy: 0, wallBy: 3_600)

        let resumed = try await agent.resumeSession()

        XCTAssertNil(paused.expectedTransitionAt)
        XCTAssertEqual(
            try XCTUnwrap(resumed.expectedTransitionAt),
            timestamp(Date(timeIntervalSince1970: 5_109.75)))
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

    func testDuePhasesAdvanceFocusThenShortBreak() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.startClassic()
        clock.advance(monotonicBy: 1_500, wallBy: 1_500)

        let afterFocus = await agent.advanceIfDue()
        clock.advance(monotonicBy: 300, wallBy: 300)
        let afterBreak = await agent.advanceIfDue()

        XCTAssertEqual(afterFocus.phaseType, .shortBreak)
        XCTAssertEqual(afterFocus.sessionState, .running)
        XCTAssertEqual(afterFocus.completedRounds, 1)
        XCTAssertEqual(afterBreak.phaseType, .focus)
        XCTAssertEqual(afterBreak.sessionState, .ready)
        XCTAssertEqual(afterBreak.completedRounds, 1)
    }

    func testSkipTransitionsFocusToShortBreakAndBreakToReadyFocus() async throws {
        let clock = TestClock()
        let agent = PomoAgentCore(productVersion: "0.1.0", clock: clock.clock)
        _ = try await agent.startClassic()

        let afterFocusSkip = try await agent.skipPhase()
        let afterBreakSkip = try await agent.skipPhase()

        XCTAssertEqual(afterFocusSkip.phaseType, .shortBreak)
        XCTAssertEqual(afterFocusSkip.sessionState, .running)
        XCTAssertEqual(afterFocusSkip.completedRounds, 0)
        XCTAssertEqual(afterBreakSkip.phaseType, .focus)
        XCTAssertEqual(afterBreakSkip.sessionState, .ready)
        XCTAssertEqual(afterBreakSkip.completedRounds, 0)
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

private func timestamp(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}
