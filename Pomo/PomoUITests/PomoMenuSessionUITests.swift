import XCTest

final class PomoMenuSessionUITests: XCTestCase {
    private var profile = ""

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        profile = "pomo-ui-test-menu-\(UUID().uuidString)"
        UserDefaults(suiteName: profile)?.removePersistentDomain(forName: profile)
    }

    func testClassicSessionControlsWorkFromStatusItem() throws {
        throw XCTSkip(
            "Blocked: Xcode 26.4 does not load accessibility for the real-runtime menu app (Ticket 02)."
        )

        let app = launchAgent()
        let welcomeWindow = app.windows["Welcome to Pomo"]
        XCTAssertTrue(welcomeWindow.waitForExistence(timeout: 10))
        welcomeWindow.buttons["Later"].click()

        openStatusItem(in: app)
        let start = app.menuItems["Start Classic"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.click()

        openStatusItem(in: app)
        let pause = app.menuItems["Pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        pause.click()

        openStatusItem(in: app)
        let resume = app.menuItems["Resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        resume.click()

        openStatusItem(in: app)
        let skip = app.menuItems["Skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.click()

        openStatusItem(in: app)
        let stop = app.menuItems["Stop Session"]
        XCTAssertTrue(stop.waitForExistence(timeout: 5))
        stop.click()
        XCTAssertTrue(app.buttons["Stop Session"].waitForExistence(timeout: 5))
        app.buttons["Stop Session"].click()

        openStatusItem(in: app)
        XCTAssertTrue(app.menuItems["Start Classic"].waitForExistence(timeout: 5))
    }

    private func openStatusItem(in app: XCUIApplication) {
        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10))
        statusItem.click()
    }

    private func launchAgent() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["POMO_TEST_PROFILE"] = profile
        app.launchEnvironment["POMO_TEST_SUPPORT_DIR"] =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(profile, isDirectory: true).path
        app.launchArguments = ["--ui-test"]
        app.launch()
        return app
    }
}
