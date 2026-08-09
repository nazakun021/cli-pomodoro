import AppKit
import PomoCore
import UserNotifications

struct PomoAgent {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)

        guard
            let applicationSupportDirectory = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first,
            let presetStore = try? PresetStore.applicationSupportStore(
                in: applicationSupportDirectory)
        else {
            return
        }
        let summaryURL =
            applicationSupportDirectory
            .appendingPathComponent("Pomo", isDirectory: true)
            .appendingPathComponent("summary.json")
        guard let summaryStore = try? SummaryStore(fileURL: summaryURL) else {
            return
        }
        let agent = PomoAgentCore(
            productVersion: "0.1.0", presetStore: presetStore, summaryStore: summaryStore)
        guard let socketPath = try? RuntimeEndpoint.prepare(),
            let server = try? LocalAgentServer(path: socketPath, agent: agent)
        else {
            return
        }
        let statusItem = IdleStatusItem(agent: agent, server: server, presetStore: presetStore)
        withExtendedLifetime(statusItem) {
            application.run()
        }
    }
}

PomoAgent.main()

@MainActor
private final class IdleStatusItem: NSObject {
    private let agent: PomoAgentCore
    private let server: LocalAgentServer
    private let presetStore: PresetStore
    private let alertPreferences: AlertPreferencesStore
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var refreshTimer: Timer?
    private var sleepObserver: NSObjectProtocol?
    private var settingsWindow: PresetSettingsWindowController?
    private var customSessionPopover: CustomSessionPopoverController?
    private var previousSnapshot: AgentSnapshot?
    private var authorizationRequested = false
    private var refreshGeneration = 0

    init(agent: PomoAgentCore, server: LocalAgentServer, presetStore: PresetStore) {
        self.agent = agent
        self.server = server
        self.presetStore = presetStore
        alertPreferences = AlertPreferencesStore()
        super.init()
        refresh()
        showWelcomeIfNeeded()
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                _ = await self.agent.handleSleep()
                self.refresh()
            }
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    private func refresh() {
        refreshGeneration += 1
        let generation = refreshGeneration
        Task { [weak self] in
            guard let self else { return }
            let snapshot = await agent.advanceIfDue()
            guard generation == refreshGeneration else { return }
            if snapshot.agentState == .session {
                requestNotificationAuthorizationIfNeeded()
            }
            deliverCompletionCue(from: previousSnapshot, to: snapshot)
            previousSnapshot = snapshot
            rebuildMenu(for: snapshot)
        }
    }

    private func rebuildMenu(for snapshot: AgentSnapshot) {
        let menu = NSMenu()
        if snapshot.agentState == .session {
            let phase = snapshot.phaseType == .focus ? "Focus" : "Break"
            let state = snapshot.sessionState?.rawValue.capitalized ?? "Unknown"
            let rounds: String
            if let targetRounds = snapshot.configuration?.targetRounds {
                rounds = "Round \((snapshot.completedRounds ?? 0) + 1) of \(targetRounds)"
            } else {
                rounds = "Round \((snapshot.completedRounds ?? 0) + 1)"
            }
            let nextPhase = snapshot.phaseType == .focus ? "Short Break" : "Focus"
            item.button?.image = NSImage(
                systemSymbolName: snapshot.phaseType == .focus ? "target" : "cup.and.saucer",
                accessibilityDescription: "Pomo \(phase) \(state)")
            item.button?.title = formatRemaining(snapshot.remainingSeconds ?? 0)
            menu.addItem(withTitle: "\(phase) - \(state)", action: nil, keyEquivalent: "")
            menu.addItem(withTitle: rounds, action: nil, keyEquivalent: "")
            menu.addItem(.separator())
            if snapshot.sessionState == .running {
                menu.addItem(withTitle: "Pause", action: #selector(pauseSession), keyEquivalent: "")
                menu.items.last?.target = self
            } else if snapshot.sessionState == .paused {
                menu.addItem(
                    withTitle: "Resume", action: #selector(resumeSession), keyEquivalent: "")
                menu.items.last?.target = self
            } else if snapshot.sessionState == .ready {
                menu.addItem(
                    withTitle: "Start", action: #selector(resumeSession), keyEquivalent: "")
                menu.items.last?.target = self
            }
            menu.addItem(withTitle: "Skip", action: #selector(skipPhase), keyEquivalent: "")
            menu.items.last?.target = self
            menu.addItem(
                withTitle: "Stop Session", action: #selector(confirmStop), keyEquivalent: "")
            menu.items.last?.target = self
            menu.addItem(withTitle: "Next: \(nextPhase)", action: nil, keyEquivalent: "")
        } else {
            item.button?.title = ""
            item.button?.image = NSImage(
                systemSymbolName: "timer", accessibilityDescription: "Pomo Idle")
            menu.addItem(withTitle: "No Session", action: nil, keyEquivalent: "")
            addQuickStartItems(to: menu)
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Presets...", action: #selector(openPresets), keyEquivalent: ",")
        menu.items.last?.target = self
        menu.addItem(withTitle: "Alerts...", action: #selector(openAlerts), keyEquivalent: "")
        menu.items.last?.target = self
        menu.addItem(withTitle: "Quit Pomo", action: #selector(quit), keyEquivalent: "q")
        menu.items.last?.target = self
        item.menu = menu
    }

    @objc private func startClassic() {
        requestNotificationAuthorizationIfNeeded()
        Task { [agent] in
            _ = try? await agent.startClassic()
            refresh()
        }
    }

    private func addQuickStartItems(to menu: NSMenu) {
        guard let defaultPreset = try? presetStore.defaultPreset() else {
            menu.addItem(
                withTitle: "Start Classic", action: #selector(startClassic), keyEquivalent: "")
            menu.items.last?.target = self
            return
        }
        addStartPresetItem(defaultPreset, title: "Start \(defaultPreset.name)", to: menu)
        for preset in (try? presetStore.recentPresets()) ?? [] {
            addStartPresetItem(preset, title: preset.name, to: menu)
        }
        menu.addItem(
            withTitle: "Custom Session...", action: #selector(openCustomSession), keyEquivalent: "")
        menu.items.last?.target = self
    }

    private func addStartPresetItem(_ preset: Preset, title: String, to menu: NSMenu) {
        let menuItem = menu.addItem(
            withTitle: title, action: #selector(startPreset(_:)), keyEquivalent: "")
        menuItem.target = self
        menuItem.representedObject = preset.id.uuidString
    }

    @objc private func startPreset(_ sender: NSMenuItem) {
        guard let idValue = sender.representedObject as? String, let id = UUID(uuidString: idValue)
        else { return }
        requestNotificationAuthorizationIfNeeded()
        Task { [agent] in
            _ = try? await agent.start(presetID: id)
            refresh()
        }
    }

    @objc private func openCustomSession() {
        requestNotificationAuthorizationIfNeeded()
        if customSessionPopover == nil {
            customSessionPopover = CustomSessionPopoverController(agent: agent, store: presetStore)
            {
                self.refresh()
            }
        }
        guard let button = item.button else { return }
        customSessionPopover?.show(relativeTo: button)
    }

    @objc private func confirmStop() {
        let alert = NSAlert()
        alert.messageText = "Stop Session?"
        alert.informativeText = "Stopping now ends this Focus Phase."
        alert.addButton(withTitle: "Stop Session")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { [agent] in
            _ = try? await agent.stopSession()
            refresh()
        }
    }

    @objc private func pauseSession() {
        Task { [agent] in
            _ = try? await agent.pauseSession()
            refresh()
        }
    }

    @objc private func resumeSession() {
        Task { [agent] in
            _ = try? await agent.resumeSession()
            refresh()
        }
    }

    @objc private func skipPhase() {
        Task { [agent] in
            _ = try? await agent.skipPhase()
            refresh()
        }
    }

    private func requestNotificationAuthorizationIfNeeded() {
        guard !authorizationRequested else { return }
        authorizationRequested = true
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]) { _, _ in }
    }

    private func deliverCompletionCue(from previous: AgentSnapshot?, to current: AgentSnapshot) {
        guard let previous,
            previous.agentState == .session,
            previous.phaseType == .focus
        else { return }
        let preferences = alertPreferences.preferences
        if preferences.soundEnabled { NSSound.beep() }
        guard preferences.notificationsEnabled else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "Pomo"
            let body: String
            if current.agentState != .session {
                body = "Focus completed."
            } else if current.phaseType == .focus {
                body = "Focus is ready."
            } else {
                body = "Break started."
            }
            content.body = body
            content.sound = preferences.soundEnabled ? .default : nil
            let phaseID = current.phaseID ?? previous.phaseID ?? UUID()
            let request = UNNotificationRequest(
                identifier: "pomo-phase-\(phaseID.uuidString)",
                content: content,
                trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }

    @objc private func openPresets() {
        if settingsWindow == nil {
            settingsWindow = PresetSettingsWindowController(store: presetStore)
        }
        settingsWindow?.showWindow(nil)
        settingsWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showWelcomeIfNeeded() {
        guard !alertPreferences.hasCompletedOnboarding else { return }
        let alert = NSAlert()
        alert.messageText = "Welcome to Pomo"
        alert.informativeText =
            "Start a Classic Focus Session from the menu bar. You can change alerts in Settings."
        alert.addButton(withTitle: "Start Classic")
        alert.addButton(withTitle: "Open Alerts")
        alert.addButton(withTitle: "Later")
        alert.alertStyle = .informational
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            startClassic()
        case .alertSecondButtonReturn:
            openAlerts()
        default:
            break
        }
        alertPreferences.hasCompletedOnboarding = true
    }

    @objc private func openAlerts() {
        let preferences = alertPreferences.preferences
        let alert = NSAlert()
        alert.messageText = "Alerts"
        alert.informativeText = "Choose which completion cues Pomo may use."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let notifications = NSButton(checkboxWithTitle: "Notifications", target: nil, action: nil)
        notifications.state = preferences.notificationsEnabled ? .on : .off
        let sound = NSButton(checkboxWithTitle: "Sound", target: nil, action: nil)
        sound.state = preferences.soundEnabled ? .on : .off
        let view = NSStackView(views: [notifications, sound])
        view.orientation = .vertical
        view.alignment = .leading
        view.spacing = 8
        alert.accessoryView = view
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        alertPreferences.preferences = AlertPreferences(
            notificationsEnabled: notifications.state == .on,
            soundEnabled: sound.state == .on)
    }

    @objc private func quit() {
        refreshTimer?.invalidate()
        if let sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
        }
        server.stop()
        NSApp.terminate(nil)
    }

    private func formatRemaining(_ seconds: Int) -> String {
        if seconds >= 3_600 {
            return String(
                format: "%d:%02d:%02d", seconds / 3_600, (seconds / 60) % 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
