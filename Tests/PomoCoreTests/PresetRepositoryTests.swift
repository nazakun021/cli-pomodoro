import Foundation
import PomoCore
import XCTest

final class PresetRepositoryTests: XCTestCase {
    func testStoreSeedsClassicAndPersistsCreatedUserPreset() throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let configuration = try SessionConfiguration(
            focusSeconds: 1_200,
            shortBreakSeconds: 240,
            longBreakSeconds: 600,
            longBreakEvery: 3,
            openEnded: false,
            targetRounds: 3,
            autoStartFocus: false,
            autoStartBreaks: true)

        let initialStore = try PresetStore(databaseURL: databaseURL)
        let created = try initialStore.create(name: "Deep Work", configuration: configuration)
        let reloadedStore = try PresetStore(databaseURL: databaseURL)

        XCTAssertEqual(try reloadedStore.defaultPreset().name, "Classic")
        XCTAssertEqual(try reloadedStore.presets(), [.classic, created])
    }

    func testCaseInsensitiveNamesAndDeletingDefaultFallsBackToClassic() throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let store = try PresetStore(databaseURL: databaseURL)
        let created = try store.create(name: "Deep Work", configuration: .classic)

        XCTAssertThrowsError(
            try store.create(name: "deep work", configuration: .classic)) {
            XCTAssertEqual($0 as? PresetStoreError, .duplicateName)
        }
        try store.selectDefault(id: created.id)
        try store.delete(id: created.id)

        XCTAssertEqual(try store.defaultPreset(), .classic)
        XCTAssertEqual(try store.presets(), [.classic])
    }

    func testDuplicateAndEditUserPresetWhileClassicRemainsProtected() throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let store = try PresetStore(databaseURL: databaseURL)
        let original = try store.create(name: "Deep Work", configuration: .classic)
        let copy = try store.duplicate(id: original.id, name: "Deep Work Copy")
        let editedConfiguration = try SessionConfiguration(
            focusSeconds: 900,
            shortBreakSeconds: 120,
            longBreakSeconds: 600,
            longBreakEvery: 2,
            openEnded: true,
            targetRounds: nil,
            autoStartFocus: true,
            autoStartBreaks: false)

        try store.update(id: original.id, name: "Writing", configuration: editedConfiguration)

        XCTAssertEqual(copy.configuration, SessionConfiguration.classic)
        XCTAssertEqual(try store.presets(), [
            .classic,
            copy,
            Preset(id: original.id, name: "Writing", configuration: editedConfiguration, isClassic: false),
        ])
        XCTAssertThrowsError(try store.update(
            id: Preset.classicID, name: "Changed", configuration: editedConfiguration)) {
            XCTAssertEqual($0 as? PresetStoreError, .classicIsProtected)
        }
        XCTAssertThrowsError(try store.delete(id: Preset.classicID)) {
            XCTAssertEqual($0 as? PresetStoreError, .classicIsProtected)
        }
    }

    private func temporaryDatabaseURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-presets-\(UUID().uuidString).sqlite")
    }
}