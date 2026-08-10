import Foundation
import PomoCore
import SQLite3
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
            try store.create(name: "deep work", configuration: .classic)
        ) {
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
        XCTAssertEqual(
            try store.presets(),
            [
                .classic,
                copy,
                Preset(
                    id: original.id, name: "Writing", configuration: editedConfiguration,
                    isClassic: false),
            ])
        XCTAssertThrowsError(
            try store.update(
                id: Preset.classicID, name: "Changed", configuration: editedConfiguration)
        ) {
            XCTAssertEqual($0 as? PresetStoreError, .classicIsProtected)
        }
        XCTAssertThrowsError(try store.delete(id: Preset.classicID)) {
            XCTAssertEqual($0 as? PresetStoreError, .classicIsProtected)
        }
    }

    func testDatabaseRejectsDirectClassicMutation() throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        _ = try PresetStore(databaseURL: databaseURL)
        var database: OpaquePointer?
        XCTAssertEqual(
            sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READWRITE, nil), SQLITE_OK)
        defer { sqlite3_close(database) }

        XCTAssertNotEqual(
            sqlite3_exec(
                database,
                "UPDATE presets SET name = 'Changed' WHERE id = '00000000-0000-0000-0000-000000000001'",
                nil,
                nil,
                nil),
            SQLITE_OK)
        XCTAssertNotEqual(
            sqlite3_exec(
                database,
                "DELETE FROM presets WHERE id = '00000000-0000-0000-0000-000000000001'",
                nil,
                nil,
                nil),
            SQLITE_OK)
    }

    func testApplicationSupportStoreUsesOwnerOnlyDirectoryAndDatabase() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-support-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = try PresetStore.applicationSupportStore(in: root)

        XCTAssertEqual(try store.defaultPreset(), .classic)
        XCTAssertEqual(fileMode(root.appendingPathComponent("Pomo")), 0o700)
        XCTAssertEqual(fileMode(root.appendingPathComponent("Pomo/pomo.sqlite")), 0o600)
    }

    func testAcceptedStartsOrderRecentsAndDeletionRemovesTheirMetadata() throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let store = try PresetStore(databaseURL: databaseURL)
        let first = try store.create(name: "First", configuration: .classic)
        let second = try store.create(name: "Second", configuration: .classic)
        let third = try store.create(name: "Third", configuration: .classic)

        try store.recordAcceptedStart(for: first.id)
        try store.recordAcceptedStart(for: second.id)
        try store.recordAcceptedStart(for: first.id)
        try store.recordAcceptedStart(for: third.id)
        try store.delete(id: first.id)

        XCTAssertEqual(try store.recentPresets(), [third, second])
    }

    func testAcceptedClassicStartUpdatesRecencyWithoutMutatingClassic() throws {
        let databaseURL = temporaryDatabaseURL()
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        let store = try PresetStore(databaseURL: databaseURL)
        let userPreset = try store.create(name: "Writing", configuration: .classic)

        try store.recordAcceptedStart(for: Preset.classicID)
        try store.selectDefault(id: userPreset.id)

        XCTAssertEqual(try store.recentPresets(), [.classic])
        XCTAssertEqual(try store.presets().first, .classic)
    }

    private func temporaryDatabaseURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-presets-\(UUID().uuidString).sqlite")
    }

    private func fileMode(_ url: URL) -> mode_t {
        var metadata = stat()
        XCTAssertEqual(stat(url.path, &metadata), 0)
        return metadata.st_mode & 0o777
    }
}
