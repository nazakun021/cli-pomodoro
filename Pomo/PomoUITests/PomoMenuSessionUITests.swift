import XCTest

final class PomoMenuSessionUITests: XCTestCase {
    private var launchedApp: XCUIApplication?
    private var profile = ""
    private var supportDirectory = URL(fileURLWithPath: "/tmp", isDirectory: true)

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        profile = "pomo-ui-test-menu-\(UUID().uuidString)"
        supportDirectory = URL(
            fileURLWithPath: "/tmp/pomo-ui-\(UUID().uuidString.prefix(8))",
            isDirectory: true)
        let defaults = UserDefaults(suiteName: profile)
        defaults?.removePersistentDomain(forName: profile)
        defaults?.set(true, forKey: "pomo.onboarding-completed")
        defaults?.set(true, forKey: "pomo.notification-explanation-shown")
    }

    override func tearDown() {
        launchedApp?.terminate()
        launchedApp = nil
        UserDefaults(suiteName: profile)?.removePersistentDomain(forName: profile)
        try? FileManager.default.removeItem(at: supportDirectory)
        super.tearDown()
    }

    func testRuntimeHostExposesIdleStatusItem() {
        let app = launchAgent()
        XCTAssertTrue(app.windows["Pomo UI Test Host"].waitForExistence(timeout: 10))
        openStatusItem(in: app)
        XCTAssertTrue(app.menuItems["Start Classic"].waitForExistence(timeout: 5))
    }

    func testIdleQuitTerminatesAgentCleanly() {
        let app = launchAgent()
        XCTAssertTrue(app.windows["Pomo UI Test Host"].waitForExistence(timeout: 10))

        openStatusItem(in: app)
        let quit = app.menuItems["Quit Pomo"]
        XCTAssertTrue(quit.waitForExistence(timeout: 5))
        quit.click()
        XCTAssertTrue(app.waitForNonExistence(timeout: 10))
        launchedApp = nil
    }

    func testAdHocAlertsExposeSoundFallback() {
        let app = launchAgent()
        XCTAssertTrue(app.windows["Pomo UI Test Host"].waitForExistence(timeout: 10))

        openStatusItem(in: app)
        let alerts = app.menuItems["Alerts..."]
        XCTAssertTrue(alerts.waitForExistence(timeout: 5))
        alerts.click()

        var dialog = app.dialogs.firstMatch
        XCTAssertTrue(dialog.waitForExistence(timeout: 5))
        XCTAssertFalse(dialog.checkBoxes["Notifications"].exists)
        let sound = dialog.checkBoxes["Sound"]
        XCTAssertTrue(sound.exists)
        XCTAssertTrue(checkboxIsOn(sound))
        sound.click()
        dialog.buttons["Save"].firstMatch.click()

        openStatusItem(in: app)
        app.menuItems["Alerts..."].click()
        dialog = app.dialogs.firstMatch
        XCTAssertTrue(dialog.waitForExistence(timeout: 5))
        XCTAssertFalse(checkboxIsOn(dialog.checkBoxes["Sound"]))
        dialog.buttons["Cancel"].firstMatch.click()
    }

    func testCustomSessionStartsConfiguredFocus() {
        let app = launchAgent()
        XCTAssertTrue(app.windows["Pomo UI Test Host"].waitForExistence(timeout: 10))

        openStatusItem(in: app)
        let custom = app.menuItems["Custom Session..."]
        XCTAssertTrue(custom.waitForExistence(timeout: 5))
        custom.click()

        let focus = app.textFields["Custom Focus"]
        let shortBreak = app.textFields["Custom Short Break"]
        let longBreak = app.textFields["Custom Long Break"]
        let cadence = app.textFields["Custom Long Break Every"]
        let rounds = app.textFields["Custom Rounds"]
        let openEnded = app.checkBoxes["Custom Open Ended"]
        let autoStartFocus = app.checkBoxes["Custom Auto Start Focus"]
        let autoStartBreaks = app.checkBoxes["Custom Auto Start Breaks"]
        let name = app.textFields["Custom Preset Name"]
        XCTAssertTrue(focus.waitForExistence(timeout: 10))
        XCTAssertTrue(focus.exists)
        XCTAssertTrue(shortBreak.exists)
        XCTAssertTrue(longBreak.exists)
        XCTAssertTrue(cadence.exists)
        XCTAssertTrue(rounds.exists)
        XCTAssertTrue(openEnded.exists)
        XCTAssertTrue(autoStartFocus.exists)
        XCTAssertTrue(autoStartBreaks.exists)
        XCTAssertTrue(name.exists)
        XCTAssertEqual(focus.value as? String, "25m")
        XCTAssertEqual(shortBreak.value as? String, "5m")
        XCTAssertEqual(longBreak.value as? String, "15m")

        replaceText("30s", in: focus, app: app)
        replaceText("2s", in: shortBreak, app: app)
        replaceText("3s", in: longBreak, app: app)
        replaceText("2", in: cadence, app: app)
        replaceText("1", in: rounds, app: app)

        let start = app.buttons["Start Custom Session"]
        XCTAssertTrue(app.buttons["Save Custom Preset"].exists)
        XCTAssertTrue(start.exists)
        start.click()
        XCTAssertTrue(app.textFields["Custom Focus"].waitForNonExistence(timeout: 5))

        openStatusItem(in: app)
        XCTAssertTrue(app.menuItems["Pause"].waitForExistence(timeout: 5))
        let stop = app.menuItems["Stop Session"]
        XCTAssertTrue(stop.waitForExistence(timeout: 5))
        stop.click()
        let confirmStop = app.dialogs.buttons["Stop Session"].firstMatch
        XCTAssertTrue(confirmStop.waitForExistence(timeout: 5))
        confirmStop.click()
        waitForStatusItem("Pomo Idle", in: app)
    }

    func testCustomSessionRetainsInvalidInput() {
        let app = launchAgent()
        XCTAssertTrue(app.windows["Pomo UI Test Host"].waitForExistence(timeout: 10))

        openStatusItem(in: app)
        app.menuItems["Custom Session..."].click()

        let focus = app.textFields["Custom Focus"]
        let shortBreak = app.textFields["Custom Short Break"]
        XCTAssertTrue(focus.waitForExistence(timeout: 10))

        replaceText("not-a-duration", in: focus, app: app)
        replaceText("2s", in: shortBreak, app: app)
        app.buttons["Start Custom Session"].click()
        XCTAssertTrue(
            app.staticTexts["Check all durations, cadence, and Session boundary values."]
                .waitForExistence(timeout: 5))
        XCTAssertEqual(shortBreak.value as? String, "2s")
        app.typeKey(.escape, modifierFlags: [])
    }

    func testPresetSettingsProtectsClassicAndManagesCopy() {
        let app = launchAgent()
        XCTAssertTrue(app.windows["Pomo UI Test Host"].waitForExistence(timeout: 10))

        openStatusItem(in: app)
        let presets = app.menuItems["Presets..."]
        XCTAssertTrue(presets.waitForExistence(timeout: 5))
        presets.click()

        let window = app.windows["Pomo Presets"]
        XCTAssertTrue(window.waitForExistence(timeout: 10))
        let name = window.textFields["Preset Name"]
        let focus = window.textFields["Preset Focus"]
        XCTAssertTrue(name.exists)
        XCTAssertFalse(name.isEnabled)
        XCTAssertFalse(window.buttons["Save"].isEnabled)
        XCTAssertFalse(window.buttons["Delete"].isEnabled)

        window.buttons["Duplicate"].click()
        XCTAssertTrue(name.isEnabled)
        XCTAssertEqual(name.value as? String, "Classic Copy")
        name.click()
        name.typeKey(.tab, modifierFlags: [])
        app.typeKey("a", modifierFlags: [.command])
        app.typeText("30m")
        XCTAssertEqual(focus.value as? String, "30m")
        focus.typeKey(.tab, modifierFlags: [.shift])
        app.typeKey("a", modifierFlags: [.command])
        app.typeText("Writing Copy")
        XCTAssertEqual(name.value as? String, "Writing Copy")

        window.buttons["Make Default"].click()
        window.buttons["Delete"].click()
        let confirmDelete = window.sheets.buttons["Delete"].firstMatch
        XCTAssertTrue(confirmDelete.waitForExistence(timeout: 5))
        confirmDelete.click()

        XCTAssertFalse(name.isEnabled)
        XCTAssertFalse(window.buttons["Delete"].isEnabled)
    }

    func testClassicSessionControlsWorkFromStatusItem() throws {
        let app = launchAgent()
        XCTAssertTrue(app.windows["Pomo UI Test Host"].waitForExistence(timeout: 10))

        openStatusItem(in: app)
        let start = app.menuItems["Start Classic"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.click()

        waitForStatusItem("Pomo Focus Running", in: app)
        openStatusItem(in: app)
        let pause = app.menuItems["Pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        pause.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()

        waitForStatusItem("Pomo Focus Paused", in: app)
        openStatusItem(in: app)
        let resume = app.menuItems["Resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        resume.click()

        waitForStatusItem("Pomo Focus Running", in: app)
        openStatusItem(in: app)
        let skip = app.menuItems["Skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.click()

        waitForStatusItem("Pomo Break Running", in: app)
        openStatusItem(in: app)
        let stop = app.menuItems["Stop Session"]
        XCTAssertTrue(stop.waitForExistence(timeout: 5))
        stop.click()
        let confirmStop = app.dialogs.buttons["Stop Session"].firstMatch
        XCTAssertTrue(confirmStop.waitForExistence(timeout: 5))
        confirmStop.click()

        waitForStatusItem("Pomo Idle", in: app)
        openStatusItem(in: app)
        XCTAssertTrue(app.menuItems["Start Classic"].waitForExistence(timeout: 5))
    }

    private func openStatusItem(in app: XCUIApplication) {
        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10))
        statusItem.click()
    }

    private func waitForStatusItem(_ label: String, in app: XCUIApplication) {
        XCTAssertTrue(app.statusItems[label].waitForExistence(timeout: 10))
    }

    private func checkboxIsOn(_ checkbox: XCUIElement) -> Bool {
        if let value = checkbox.value as? NSNumber { return value.boolValue }
        if let value = checkbox.value as? String { return value == "1" }
        return checkbox.isSelected
    }

    private func replaceText(_ value: String, in field: XCUIElement, app: XCUIApplication) {
        field.doubleClick()
        field.typeKey(.delete, modifierFlags: [])
        field.typeText(value)
    }

    private func launchAgent() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["POMO_TEST_PROFILE"] = profile
        app.launchEnvironment["POMO_UI_TEST_MODE"] = "runtime-host"
        app.launchEnvironment["POMO_TEST_SUPPORT_DIR"] = supportDirectory.path
        app.launchArguments = ["--ui-test"]
        app.launch()
        launchedApp = app
        return app
    }
}
