import AppKit
import PomoCore
import SwiftUI

@MainActor
final class CustomSessionPopoverController {
    private let popover = NSPopover()

    init(
        agent: PomoAgentCore,
        store: PresetStore,
        onStarted: @escaping @MainActor () -> Void
    ) {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 540)
        popover.contentViewController = NSHostingController(
            rootView: CustomSessionView(
                agent: agent,
                store: store,
                onStarted: onStarted))
    }

    func show(relativeTo button: NSStatusBarButton) {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

@MainActor
final class CustomSessionModel: ObservableObject {
    private let agent: PomoAgentCore
    private let store: PresetStore
    private let onStarted: @MainActor () -> Void
    private let mainRunLoopDispatcher = MainRunLoopDispatcher()

    @Published var presets: [Preset] = []
    @Published var selectedPresetID: UUID?
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

    init(
        agent: PomoAgentCore,
        store: PresetStore,
        onStarted: @escaping @MainActor () -> Void
    ) {
        self.agent = agent
        self.store = store
        self.onStarted = onStarted
        reloadPresets()
    }

    func reloadPresets() {
        do {
            presets = try store.presets()
            if selectedPresetID == nil { selectedPresetID = try store.defaultPreset().id }
            loadSelectedPreset()
        } catch {
            message = "Unable to load Presets."
        }
    }

    func loadSelectedPreset() {
        guard let preset = presets.first(where: { $0.id == selectedPresetID }) else { return }
        let configuration = preset.configuration
        focus = "\(configuration.focusSeconds)s"
        shortBreak = "\(configuration.shortBreakSeconds)s"
        longBreak = "\(configuration.longBreakSeconds)s"
        cadence = "\(configuration.longBreakEvery)"
        rounds = configuration.targetRounds.map(String.init) ?? ""
        openEnded = configuration.openEnded
        autoStartFocus = configuration.autoStartFocus
        autoStartBreaks = configuration.autoStartBreaks
        message = ""
    }

    func startOnce() {
        do {
            let configuration = try configuration()
            let sourcePresetID = selectedPresetID
            let dispatcher = mainRunLoopDispatcher
            Task.detached { [weak self, agent, dispatcher] in
                do {
                    _ = try await agent.start(
                        configuration: configuration, sourcePresetID: sourcePresetID)
                    dispatcher.dispatch { [weak self] in
                        self?.onStarted()
                    }
                } catch {
                    dispatcher.dispatch { [weak self] in
                        self?.message =
                            "An active Session must be stopped before starting another."
                    }
                }
            }
        } catch {
            message = "Check all durations, cadence, and Session boundary values."
        }
    }

    func saveAsPreset() {
        do {
            let created = try store.create(name: name, configuration: configuration())
            selectedPresetID = created.id
            reloadPresets()
            message = "Preset saved. Select Start Once when ready."
        } catch {
            message = "Use a unique name and valid Session values."
        }
    }

    private func configuration() throws -> SessionConfiguration {
        try PresetConfigurationDraft(
            focus: focus, shortBreak: shortBreak, longBreak: longBreak,
            longBreakEvery: cadence, rounds: rounds, openEnded: openEnded,
            autoStartFocus: autoStartFocus, autoStartBreaks: autoStartBreaks
        ).configuration()
    }
}

private struct CustomSessionView: View {
    @StateObject private var model: CustomSessionModel

    init(
        agent: PomoAgentCore,
        store: PresetStore,
        onStarted: @escaping @MainActor () -> Void
    ) {
        _model = StateObject(
            wrappedValue: CustomSessionModel(
                agent: agent,
                store: store,
                onStarted: onStarted))
    }

    var body: some View {
        Form {
            Picker("Base Preset", selection: $model.selectedPresetID) {
                ForEach(model.presets, id: \.id) { preset in
                    Text(preset.name).tag(Optional(preset.id))
                }
            }
            .accessibilityIdentifier("Custom Base Preset")
            .onChange(of: model.selectedPresetID) { _ in model.loadSelectedPreset() }
            TextField("Focus", text: $model.focus)
                .accessibilityIdentifier("Custom Focus")
            TextField("Short Break", text: $model.shortBreak)
                .accessibilityIdentifier("Custom Short Break")
            TextField("Long Break", text: $model.longBreak)
                .accessibilityIdentifier("Custom Long Break")
            TextField("Long Break Every", text: $model.cadence)
                .accessibilityIdentifier("Custom Long Break Every")
            Toggle("Open-ended", isOn: $model.openEnded)
                .accessibilityIdentifier("Custom Open Ended")
            TextField("Rounds", text: $model.rounds).disabled(model.openEnded)
                .accessibilityIdentifier("Custom Rounds")
            Toggle("Auto-start Focus", isOn: $model.autoStartFocus)
                .accessibilityIdentifier("Custom Auto Start Focus")
            Toggle("Auto-start Breaks", isOn: $model.autoStartBreaks)
                .accessibilityIdentifier("Custom Auto Start Breaks")
            TextField("Preset Name", text: $model.name)
                .accessibilityIdentifier("Custom Preset Name")
            if !model.message.isEmpty {
                Text(model.message)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("Custom Session Message")
            }
            HStack {
                Button("Save as Preset", action: model.saveAsPreset)
                    .accessibilityIdentifier("Save Custom Preset")
                Spacer()
                Button("Start Once", action: model.startOnce)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("Start Custom Session")
            }
        }
        .padding()
        .frame(width: 360)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Custom Session")
    }
}
