import AppKit
import PomoCore
import SwiftUI

@MainActor
final class PresetSettingsWindowController: NSWindowController {
    init(store: PresetStore) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "Pomo Presets"
        window.contentViewController = NSHostingController(
            rootView: PresetSettingsView(store: store))
        super.init(window: window)
    }

    required init?(coder: NSCoder) { nil }
}

@MainActor
private final class PresetSettingsModel: ObservableObject {
    let store: PresetStore
    @Published var presets: [Preset] = []
    @Published var selectedID: UUID?
    @Published var name = ""
    @Published var focus = "25m"
    @Published var shortBreak = "5m"
    @Published var longBreak = "15m"
    @Published var cadence = "4"
    @Published var rounds = "4"
    @Published var openEnded = false
    @Published var autoStartFocus = false
    @Published var autoStartBreaks = true
    @Published var message = ""

    init(store: PresetStore) {
        self.store = store
        reload()
    }

    var selectedPreset: Preset? { presets.first { $0.id == selectedID } }
    var isClassic: Bool { selectedPreset?.isClassic == true }

    func reload() {
        do {
            presets = try store.presets()
            if selectedID == nil { selectedID = try store.defaultPreset().id }
            loadSelected()
        } catch { message = "Unable to load Presets." }
    }

    func loadSelected() {
        guard let preset = selectedPreset else { return }
        name = preset.name
        focus = "\(preset.configuration.focusSeconds)s"
        shortBreak = "\(preset.configuration.shortBreakSeconds)s"
        longBreak = "\(preset.configuration.longBreakSeconds)s"
        cadence = "\(preset.configuration.longBreakEvery)"
        rounds = preset.configuration.targetRounds.map(String.init) ?? ""
        openEnded = preset.configuration.openEnded
        autoStartFocus = preset.configuration.autoStartFocus
        autoStartBreaks = preset.configuration.autoStartBreaks
        message = preset.isClassic ? "Classic is read-only. Duplicate it to customize." : ""
    }

    func save() {
        do {
            let draft = PresetConfigurationDraft(
                focus: focus, shortBreak: shortBreak, longBreak: longBreak,
                longBreakEvery: cadence, rounds: rounds, openEnded: openEnded,
                autoStartFocus: autoStartFocus, autoStartBreaks: autoStartBreaks)
            let configuration = try draft.configuration()
            if let preset = selectedPreset, !preset.isClassic {
                try store.update(id: preset.id, name: name, configuration: configuration)
            } else {
                let created = try store.create(name: name, configuration: configuration)
                selectedID = created.id
            }
            reload()
            message = "Saved."
        } catch { message = "Check the name and all configuration values." }
    }

    func duplicate() {
        guard let preset = selectedPreset else { return }
        do {
            let copy = try store.duplicate(id: preset.id, name: "\(preset.name) Copy")
            selectedID = copy.id
            reload()
            message = "Duplicated."
        } catch { message = "Could not duplicate this Preset." }
    }

    func selectDefault() {
        guard let id = selectedID else { return }
        do {
            try store.selectDefault(id: id)
            message = "Default Preset updated."
        } catch { message = "Could not set the default Preset." }
    }

    func delete() {
        guard let id = selectedID else { return }
        do {
            try store.delete(id: id)
            selectedID = Preset.classicID
            reload()
            message = "Deleted."
        } catch { message = "Could not delete this Preset." }
    }
}

private struct PresetSettingsView: View {
    @StateObject private var model: PresetSettingsModel
    @State private var confirmDeletion = false

    init(store: PresetStore) {
        _model = StateObject(wrappedValue: PresetSettingsModel(store: store))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("Preset", selection: $model.selectedID) {
                    ForEach(model.presets, id: \.id) { preset in
                        Text(preset.name + (preset.isClassic ? " (Classic)" : "")).tag(
                            Optional(preset.id))
                    }
                }
                .onChange(of: model.selectedID) { _ in model.loadSelected() }
                Button("Duplicate", action: model.duplicate).disabled(model.selectedID == nil)
                Button("Make Default", action: model.selectDefault).disabled(
                    model.selectedID == nil)
            }
            Form {
                TextField("Name", text: $model.name).disabled(model.isClassic)
                TextField("Focus", text: $model.focus).disabled(model.isClassic)
                TextField("Short Break", text: $model.shortBreak).disabled(model.isClassic)
                TextField("Long Break", text: $model.longBreak).disabled(model.isClassic)
                TextField("Long Break Every", text: $model.cadence).disabled(model.isClassic)
                Toggle("Open-ended", isOn: $model.openEnded).disabled(model.isClassic)
                TextField("Rounds", text: $model.rounds).disabled(
                    model.isClassic || model.openEnded)
                Toggle("Auto-start Focus", isOn: $model.autoStartFocus).disabled(model.isClassic)
                Toggle("Auto-start Breaks", isOn: $model.autoStartBreaks).disabled(model.isClassic)
            }
            Text(model.message).foregroundStyle(.secondary).accessibilityLabel(model.message)
            HStack {
                Button("Save", action: model.save).disabled(model.isClassic)
                Button("New") {
                    model.selectedID = nil
                    model.name = ""
                    model.message = "Enter a name and configuration."
                }
                Spacer()
                Button("Delete", role: .destructive) { confirmDeletion = true }
                    .disabled(model.isClassic || model.selectedID == nil)
                    .confirmationDialog("Delete this Preset?", isPresented: $confirmDeletion) {
                        Button("Delete", role: .destructive, action: model.delete)
                    } message: {
                        Text("Deleting the default switches the default back to Classic.")
                    }
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 480)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pomo Presets Settings")
    }
}
