import XCTest

final class PomoOnboardingUITests: XCTestCase {
    private var profile = ""

    override func setUp() {
        super.setUp()
        profile = "pomo-ui-test-onboarding-\(UUID().uuidString)"
        UserDefaults(suiteName: profile)?.removePersistentDomain(forName: profile)
    }

    func testWelcomeOffersAccessibleFirstLaunchActions() {
        let app = launchAgent()
        let welcomeWindow = app.windows["Welcome to Pomo"]

        XCTAssertTrue(
            welcomeWindow.waitForExistence(timeout: 10),
            "Welcome popover title was not exposed")
        XCTAssertTrue(
            welcomeWindow.buttons["Start Classic"].exists,
            "Start Classic is not accessible")
        XCTAssertTrue(
            welcomeWindow.buttons["Open Alerts"].exists,
            "Open Alerts is not accessible")
        XCTAssertTrue(welcomeWindow.buttons["Later"].exists, "Later is not accessible")
        XCTAssertTrue(
            welcomeWindow.checkBoxes["Launch at Login (off by default)"].exists,
            "Launch-at-login checkbox is not accessible")

        welcomeWindow.buttons["Later"].click()
        XCTAssertFalse(welcomeWindow.waitForExistence(timeout: 1))
    }

    private func launchAgent() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "com.nazakun.pomo")
        app.launchEnvironment["POMO_TEST_PROFILE"] = profile
        app.launchEnvironment["POMO_TEST_SUPPORT_DIR"] =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(profile, isDirectory: true).path
        app.launchArguments = ["--ui-test"]
        app.launch()
        return app
    }

}
