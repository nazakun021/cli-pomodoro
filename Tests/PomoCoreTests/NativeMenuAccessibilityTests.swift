import ApplicationServices
import CoreGraphics
import Foundation
import PomoCore
import XCTest

final class NativeMenuAccessibilityTests: XCTestCase {
    func testPackagedIdleMenuMatchesSocketSnapshot() async throws {
        let fixture = try await launchFixture()
        defer { fixture.stop() }

        let response = try await waitForStatus(at: fixture.socketPath)
        XCTAssertTrue(response.ok)
        XCTAssertEqual(response.data?.agentState, .idle)
        XCTAssertEqual(response.data?.revision, 0)

        try await openStatusMenu(in: fixture.application, description: "Pomo Idle")
        _ = try await waitForElement(in: fixture.application) { element in
            attributeString(element, kAXRoleAttribute) == kAXMenuItemRole
                && attributeString(element, kAXTitleAttribute) == "Start Classic"
        }
    }

    private func launchFixture() async throws -> NativeMenuFixture {
        guard let appPath = ProcessInfo.processInfo.environment["POMO_TEST_APP_PATH"] else {
            throw XCTSkip("Set POMO_TEST_APP_PATH to run packaged native menu validation.")
        }
        guard AXIsProcessTrusted() else {
            XCTFail("Accessibility permission is required for native menu validation.")
            throw NativeMenuValidationError.unavailable("Accessibility permission")
        }

        let supportDirectory = URL(
            fileURLWithPath: "/tmp/pomo-native-menu-\(UUID().uuidString.prefix(8))",
            isDirectory: true)
        let profile = "pomo-native-menu-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: profile))
        defaults.set(true, forKey: "pomo.onboarding-completed")
        defaults.set(true, forKey: "pomo.notification-explanation-shown")

        let appURL = URL(fileURLWithPath: appPath, isDirectory: true)
        let bundle = try XCTUnwrap(Bundle(url: appURL))
        let executableURL = try XCTUnwrap(bundle.executableURL)
        let process = Process()
        process.executableURL = executableURL
        process.environment = ProcessInfo.processInfo.environment.merging([
            "POMO_TEST_PROFILE": profile,
            "POMO_TEST_SUPPORT_DIR": supportDirectory.path,
        ]) { _, isolatedValue in isolatedValue }
        try process.run()

        let socketPath = try RuntimeEndpoint.prepare(in: supportDirectory)
        let application = AXUIElementCreateApplication(process.processIdentifier)
        let fixture = NativeMenuFixture(
            process: process,
            application: application,
            socketPath: socketPath,
            supportDirectory: supportDirectory,
            profile: profile)
        do {
            _ = try await waitForStatus(at: socketPath)
            return fixture
        } catch {
            fixture.stop()
            throw error
        }
    }
}

private final class NativeMenuFixture {
    let process: Process
    let application: AXUIElement
    let socketPath: String
    private let supportDirectory: URL
    private let profile: String
    private var stopped = false

    init(
        process: Process,
        application: AXUIElement,
        socketPath: String,
        supportDirectory: URL,
        profile: String
    ) {
        self.process = process
        self.application = application
        self.socketPath = socketPath
        self.supportDirectory = supportDirectory
        self.profile = profile
    }

    func stop() {
        guard !stopped else { return }
        stopped = true
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        UserDefaults(suiteName: profile)?.removePersistentDomain(forName: profile)
        try? FileManager.default.removeItem(at: supportDirectory)
    }
}

private func openStatusMenu(in application: AXUIElement, description: String) async throws {
    let statusItem = try await waitForElement(in: application) { element in
        attributeString(element, kAXDescriptionAttribute) == description
            && actionNames(of: element).contains(kAXPressAction)
    }
    try click(statusItem)
}

private func waitForStatus(at socketPath: String) async throws -> PublicResponse {
    try await waitForStatus(at: socketPath, expecting: "reachable Agent") { _ in true }
}

private func waitForStatus(
    at socketPath: String,
    expecting expectation: String,
    matching predicate: (AgentSnapshot) -> Bool
) async throws -> PublicResponse {
    let deadline = Date().addingTimeInterval(10)
    var lastError: Error?
    var lastSnapshot: AgentSnapshot?
    while Date() < deadline {
        do {
            let response = try await LocalAgentClient(path: socketPath).status()
            lastSnapshot = response.data
            if let snapshot = lastSnapshot, predicate(snapshot) { return response }
        } catch {
            lastError = error
        }
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    let observed =
        lastSnapshot.map {
            "revision \($0.revision), agent \($0.agentState.rawValue), session \($0.sessionState?.rawValue ?? "none")"
        } ?? "no snapshot"
    throw lastError
        ?? NativeMenuValidationError.timedOut("\(expectation); last observed \(observed)")
}

private func waitForElement(
    in application: AXUIElement,
    matching predicate: (AXUIElement) -> Bool
) async throws -> AXUIElement {
    let deadline = Date().addingTimeInterval(10)
    while Date() < deadline {
        if let element = firstElement(in: application, matching: predicate) {
            return element
        }
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    throw NativeMenuValidationError.timedOut("Accessibility element")
}

private func firstElement(
    in root: AXUIElement,
    matching predicate: (AXUIElement) -> Bool
) -> AXUIElement? {
    var pending = [root]
    var visited = Set<CFHashCode>()
    while let element = pending.popLast() {
        guard visited.insert(CFHash(element)).inserted else { continue }
        if predicate(element) { return element }
        pending.append(contentsOf: childElements(of: element))
    }
    return nil
}

private func childElements(of element: AXUIElement) -> [AXUIElement] {
    guard let value = attributeValue(element, kAXChildrenAttribute) else { return [] }
    return value as? [AXUIElement] ?? []
}

private func actionNames(of element: AXUIElement) -> [String] {
    var names: CFArray?
    guard AXUIElementCopyActionNames(element, &names) == .success else { return [] }
    return names as? [String] ?? []
}

private func click(_ element: AXUIElement) throws {
    try click(at: centerPoint(of: element))
}

private func centerPoint(of element: AXUIElement) throws -> CGPoint {
    guard let position = attributePoint(element, kAXPositionAttribute),
        let size = attributeSize(element, kAXSizeAttribute)
    else { throw NativeMenuValidationError.unavailable("Status item frame") }
    return CGPoint(x: position.x + size.width / 2, y: position.y + size.height / 2)
}

private func click(at point: CGPoint) throws {
    guard
        let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left),
        let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left)
    else { throw NativeMenuValidationError.unavailable("Mouse event") }
    mouseDown.post(tap: .cghidEventTap)
    mouseUp.post(tap: .cghidEventTap)
}

private func attributePoint(_ element: AXUIElement, _ attribute: String) -> CGPoint? {
    guard let value = attributeAXValue(element, attribute), AXValueGetType(value) == .cgPoint
    else { return nil }
    var point = CGPoint.zero
    guard AXValueGetValue(value, .cgPoint, &point) else { return nil }
    return point
}

private func attributeSize(_ element: AXUIElement, _ attribute: String) -> CGSize? {
    guard let value = attributeAXValue(element, attribute), AXValueGetType(value) == .cgSize
    else { return nil }
    var size = CGSize.zero
    guard AXValueGetValue(value, .cgSize, &size) else { return nil }
    return size
}

private func attributeAXValue(_ element: AXUIElement, _ attribute: String) -> AXValue? {
    guard let value = attributeValue(element, attribute), CFGetTypeID(value) == AXValueGetTypeID()
    else { return nil }
    return unsafeDowncast(value, to: AXValue.self)
}

private func attributeString(_ element: AXUIElement, _ attribute: String) -> String? {
    attributeValue(element, attribute) as? String
}

private func attributeValue(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard
        AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success
    else { return nil }
    return value
}

private enum NativeMenuValidationError: Error {
    case timedOut(String)
    case unavailable(String)
}
