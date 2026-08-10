import XCTest

final class PomoOnboardingUITests: XCTestCase {
    private let profile = "pomo-ui-test-onboarding"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: profile)?.removePersistentDomain(forName: profile)
    }

    func testWelcomeOffersAccessibleFirstLaunchActions() {
        let app = launchAgent()

        XCTAssertTrue(
            app.staticTexts["Welcome to Pomo"].waitForExistence(timeout: 5),
            "Welcome popover title was not exposed")
        XCTAssertTrue(app.buttons["Start Classic"].exists, "Start Classic is not accessible")
        XCTAssertTrue(app.buttons["Open Alerts"].exists, "Open Alerts is not accessible")
        XCTAssertTrue(app.buttons["Later"].exists, "Later is not accessible")
        XCTAssertTrue(
            app.checkBoxes["Launch at Login (off by default)"].exists,
            "Launch-at-login checkbox is not accessible")

        app.buttons["Later"].click()
        XCTAssertFalse(app.staticTexts["Welcome to Pomo"].waitForExistence(timeout: 1))
    }

    private func launchAgent() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "com.nazakun.pomo")
        app.launchEnvironment["POMO_TEST_PROFILE"] = profile
        app.launchEnvironment["POMO_TEST_SUPPORT_DIR"] =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(profile, isDirectory: true).path
        app.launchArguments = ["--ui-test"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10), "Pomo did not activate")
        return app
    }

}
