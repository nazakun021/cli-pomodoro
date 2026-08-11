import PomoCore
import XCTest

@testable import PomoAgentKit

@MainActor
final class CustomSessionTests: XCTestCase {
    func testSaveAsPresetPersistsConfigurationAndKeepsStartAvailable() throws {
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-custom-session-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let store = try PresetStore(databaseURL: databaseURL)
        let model = CustomSessionModel(
            agent: PomoAgentCore(productVersion: "0.1.0"),
            store: store,
            onStarted: {})
        model.name = "Quick Work"
        model.focus = "30s"
        model.shortBreak = "2s"
        model.longBreak = "3s"
        model.cadence = "2"
        model.rounds = "1"

        model.saveAsPreset()

        let saved = try store.presets().first { $0.name == "Quick Work" }
        XCTAssertEqual(saved?.configuration.focusSeconds, 30)
        XCTAssertEqual(saved?.configuration.shortBreakSeconds, 2)
        XCTAssertEqual(saved?.configuration.longBreakSeconds, 3)
        XCTAssertEqual(saved?.configuration.longBreakEvery, 2)
        XCTAssertEqual(saved?.configuration.targetRounds, 1)
        XCTAssertEqual(model.message, "Preset saved. Select Start Once when ready.")
        XCTAssertEqual(model.selectedPresetID, saved?.id)
    }

    func testInvalidSaveLeavesExistingPresetsUntouched() throws {
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-custom-session-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        let store = try PresetStore(databaseURL: databaseURL)
        let model = CustomSessionModel(
            agent: PomoAgentCore(productVersion: "0.1.0"),
            store: store,
            onStarted: {})
        model.name = "Invalid Work"
        model.focus = "not-a-duration"

        model.saveAsPreset()

        XCTAssertNil(try store.presets().first { $0.name == "Invalid Work" })
        XCTAssertEqual(model.message, "Use a unique name and valid Session values.")
    }
}
