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

    func dismiss() {
        guard popover.isShown else { return }
        popover.performClose(nil)
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
    @Published var restSessions = "3"
    @Published var openEnded = false
    @Published var autoStartFocus = false
    @Published var autoStartBreaks = true
    @Published var message = ""
    @Published var isStarting = false

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
        focus = durationInput(configuration.focusSeconds)
        shortBreak = durationInput(configuration.shortBreakSeconds)
        longBreak = durationInput(configuration.longBreakSeconds)
        cadence = "\(configuration.longBreakEvery)"
        restSessions = configuration.targetRounds.map { "\(max(0, $0 - 1))" } ?? "3"
        openEnded = configuration.openEnded
        autoStartFocus = configuration.autoStartFocus
        autoStartBreaks = configuration.autoStartBreaks
        message = ""
    }

    func startOnce() {
        guard !isStarting else { return }
        do {
            let configuration = try configuration()
            let sourcePresetID = selectedPresetID
            isStarting = true
            message = "Starting Session..."
            let dispatcher = mainRunLoopDispatcher
            Task.detached { [weak self, agent, dispatcher] in
                do {
                    _ = try await agent.start(
                        configuration: configuration, sourcePresetID: sourcePresetID)
                    dispatcher.dispatch { [weak self] in
                        guard let self else { return }
                        self.isStarting = false
                        self.onStarted()
                    }
                } catch {
                    dispatcher.dispatch { [weak self] in
                        self?.isStarting = false
                        self?.message =
                            "An active Session must be stopped before starting another."
                    }
                }
            }
        } catch {
            isStarting = false
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
            longBreakEvery: cadence, rounds: targetRoundsInput, openEnded: openEnded,
            autoStartFocus: autoStartFocus, autoStartBreaks: autoStartBreaks
        ).configuration()
    }

    private var targetRoundsInput: String {
        guard let restSessions = Int(restSessions), restSessions >= 0 else { return "" }
        return "\(restSessions + 1)"
    }

    var rounds: String {
        get { targetRoundsInput }
        set {
            guard let targetRounds = Int(newValue), targetRounds >= 1 else {
                restSessions = newValue
                return
            }
            restSessions = "\(targetRounds - 1)"
        }
    }

    private func durationInput(_ seconds: Int) -> String {
        if seconds % 3_600 == 0 { return "\(seconds / 3_600)h" }
        if seconds % 60 == 0 { return "\(seconds / 60)m" }
        return "\(seconds)s"
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
            Section("Focus session") {
                Picker("Start from", selection: $model.selectedPresetID) {
                    ForEach(model.presets, id: \.id) { preset in
                        Text(preset.name).tag(Optional(preset.id))
                    }
                }
                .accessibilityIdentifier("Custom Base Preset")
                .onChange(of: model.selectedPresetID) { _ in model.loadSelectedPreset() }
                TextField("Focus duration", text: $model.focus)
                    .accessibilityIdentifier("Custom Focus")
                TextField("Rest breaks", text: $model.restSessions)
                    .disabled(model.openEnded)
                    .accessibilityIdentifier("Custom Rounds")
                    .accessibilityLabel("Rest breaks")
                Toggle("Open-ended session", isOn: $model.openEnded)
                    .accessibilityIdentifier("Custom Open Ended")
            }
            Section("Rest") {
                TextField("Short break duration", text: $model.shortBreak)
                    .accessibilityIdentifier("Custom Short Break")
                TextField("Long break duration", text: $model.longBreak)
                    .accessibilityIdentifier("Custom Long Break")
                TextField("Long break after every", text: $model.cadence)
                    .accessibilityIdentifier("Custom Long Break Every")
            }
            Section("Automation") {
                Toggle("Auto-start Focus", isOn: $model.autoStartFocus)
                    .accessibilityIdentifier("Custom Auto Start Focus")
                Toggle("Auto-start breaks", isOn: $model.autoStartBreaks)
                    .accessibilityIdentifier("Custom Auto Start Breaks")
            }
            Section("Save") {
                TextField("Preset name", text: $model.name)
                    .accessibilityIdentifier("Custom Preset Name")
            }
            if !model.message.isEmpty {
                Text(model.message)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("Custom Session Message")
            }
            HStack {
                Button("Save as Preset", action: model.saveAsPreset)
                    .accessibilityIdentifier("Save Custom Preset")
                    .disabled(model.isStarting)
                Spacer()
                Button("Start Once", action: model.startOnce)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("Start Custom Session")
                    .disabled(model.isStarting)
            }
        }
        .padding()
        .frame(width: 360)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Custom Session")
    }
}
