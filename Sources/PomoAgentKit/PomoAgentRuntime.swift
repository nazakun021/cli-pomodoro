import AppKit
import PomoCore
import ServiceManagement
@preconcurrency import UserNotifications

private func localDateString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

private var notificationsAvailable: Bool {
    Bundle.main.bundleIdentifier != nil
}

public struct PomoAgent {
    @MainActor
    public static func main() async {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableAutomaticTermination(
            "Pomo Agent must remain available for menu and CLI commands")

        let environment = ProcessInfo.processInfo.environment
        if environment["POMO_UI_TEST_MODE"] == "onboarding",
            let testProfile = environment["POMO_TEST_PROFILE"]
        {
            application.setActivationPolicy(.regular)
            let defaults = UserDefaults(suiteName: testProfile) ?? .standard
            let alertPreferences = AlertPreferencesStore(defaults: defaults)
            if !alertPreferences.hasCompletedOnboarding {
                let welcome = WelcomePopoverController(
                    onStart: { _ in alertPreferences.hasCompletedOnboarding = true },
                    onAlerts: { _ in alertPreferences.hasCompletedOnboarding = true },
                    onLater: { _ in alertPreferences.hasCompletedOnboarding = true })
                DispatchQueue.main.async {
                    welcome.show(relativeTo: nil)
                }
                withExtendedLifetime(welcome) {
                    application.run()
                }
            } else {
                application.run()
            }
            return
        }
        if environment["POMO_TEST_PROFILE"] != nil {
            application.setActivationPolicy(.regular)
        }
        let applicationSupportDirectory: URL
        if let testSupportDirectory = environment["POMO_TEST_SUPPORT_DIR"] {
            applicationSupportDirectory = URL(
                fileURLWithPath: testSupportDirectory, isDirectory: true)
            try? FileManager.default.createDirectory(
                at: applicationSupportDirectory, withIntermediateDirectories: true)
        } else if let standardSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first {
            applicationSupportDirectory = standardSupportDirectory
        } else {
            return
        }
        guard
            let presetStore = try? PresetStore.applicationSupportStore(
                in: applicationSupportDirectory)
        else { return }
        let preferencesDefaults =
            environment["POMO_TEST_PROFILE"]
            .flatMap(UserDefaults.init(suiteName:)) ?? .standard
        let alertPreferences = AlertPreferencesStore(defaults: preferencesDefaults)
        let lifecycleStore = AgentLifecycleStore(defaults: preferencesDefaults)
        let summaryURL =
            applicationSupportDirectory
            .appendingPathComponent("Pomo", isDirectory: true)
            .appendingPathComponent("summary.json")
        guard let summaryStore = try? SummaryStore(fileURL: summaryURL) else {
            return
        }
        let agent = PomoAgentCore(
            productVersion: "0.1.0", presetStore: presetStore, summaryStore: summaryStore)
        let snapshot = await agent.snapshot()
        lifecycleStore.markRunning(
            instanceID: snapshot.agentInstanceID ?? UUID(),
            hasActiveSession: snapshot.agentState == .session)
        let socketPath: String?
        if environment["POMO_TEST_PROFILE"] != nil {
            socketPath = try? RuntimeEndpoint.prepare(in: applicationSupportDirectory)
        } else {
            socketPath = try? RuntimeEndpoint.prepare()
        }
        guard let socketPath,
            let server = try? LocalAgentServer(path: socketPath, agent: agent)
        else {
            return
        }
        let priorInterruption = lifecycleStore.consumeUnexpectedTermination()
        let statusItem = IdleStatusItem(
            agent: agent, server: server, presetStore: presetStore, lifecycleStore: lifecycleStore,
            priorInterruption: priorInterruption, alertPreferences: alertPreferences)
        let notificationDelegate: PomoNotificationDelegate?
        if notificationsAvailable {
            let delegate = PomoNotificationDelegate(
                agent: agent, openStatus: { statusItem.showStatus() })
            notificationDelegate = delegate
            UNUserNotificationCenter.current().delegate = delegate
            let startNext = UNNotificationAction(
                identifier: "POMO_START_NEXT", title: "Start Next Phase", options: [])
            let phaseCategory = UNNotificationCategory(
                identifier: "POMO_PHASE", actions: [startNext], intentIdentifiers: [])
            UNUserNotificationCenter.current().setNotificationCategories([phaseCategory])
        } else {
            notificationDelegate = nil
        }
        withExtendedLifetime(statusItem) {
            withExtendedLifetime(notificationDelegate) {
                application.run()
            }
        }
    }
}

private final class MenuActionTarget: NSObject {
    private let handler: @MainActor () -> Void

    init(handler: @escaping @MainActor () -> Void) {
        self.handler = handler
    }

    @objc func invokeMenuAction() {
        let handler = handler
        MainActor.assumeIsolated {
            handler()
        }
    }
}

final class MainRunLoopDispatcher: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var pendingAction: (@MainActor () -> Void)?

    func dispatch(_ action: @escaping @MainActor () -> Void) {
        lock.lock()
        pendingAction = action
        lock.unlock()
        performSelector(onMainThread: #selector(runPendingAction), with: nil, waitUntilDone: false)
    }

    @objc private func runPendingAction() {
        lock.lock()
        let action = pendingAction
        pendingAction = nil
        lock.unlock()
        guard let action else { return }
        MainActor.assumeIsolated {
            action()
        }
    }
}

@MainActor
private final class IdleStatusItem: NSObject, NSMenuDelegate {
    private let agent: PomoAgentCore
    private let server: LocalAgentServer
    private let presetStore: PresetStore
    private let lifecycleStore: AgentLifecycleStore
    private let priorInterruption: AgentLifecycleMarker?
    private let alertPreferences: AlertPreferencesStore
    private let mainRunLoopDispatcher = MainRunLoopDispatcher()
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var refreshTimer: Timer?
    private var sleepObserver: NSObjectProtocol?
    private var settingsWindow: PresetSettingsWindowController?
    private var customSessionPopover: CustomSessionPopoverController?
    private var welcomePopover: WelcomePopoverController?
    private var previousSnapshot: AgentSnapshot?
    private var authorizationRequested = false
    private var refreshGeneration = 0
    private var isQuitting = false
    private var missedAlert = false
    private var missedAlertGeneration = 0
    private var isExplainingNotifications = false
    private var menuActionTargets: [MenuActionTarget] = []
    private var isMenuOpen = false

    init(
        agent: PomoAgentCore,
        server: LocalAgentServer,
        presetStore: PresetStore,
        lifecycleStore: AgentLifecycleStore,
        priorInterruption: AgentLifecycleMarker?,
        alertPreferences: AlertPreferencesStore
    ) {
        self.agent = agent
        self.server = server
        self.presetStore = presetStore
        self.lifecycleStore = lifecycleStore
        self.priorInterruption = priorInterruption
        self.alertPreferences = alertPreferences
        missedAlert = alertPreferences.hasMissedAlert
        super.init()
        item.length = NSStatusItem.variableLength
        item.isVisible = true
        item.button?.title = ""
        item.button?.image = NSImage(
            systemSymbolName: "target", accessibilityDescription: "Pomo Idle")
        let initialMenu = NSMenu()
        addMenuAction(to: initialMenu, title: "Start Classic") { [weak self] in
            self?.startClassic()
        }
        initialMenu.addItem(.separator())
        addMenuAction(to: initialMenu, title: "Presets...", keyEquivalent: ",") {
            [weak self] in self?.openPresets()
        }
        addMenuAction(to: initialMenu, title: "Alerts...") { [weak self] in
            self?.openAlerts()
        }
        addMenuAction(to: initialMenu, title: "Quit Pomo", keyEquivalent: "q") {
            [weak self] in self?.quit()
        }
        item.menu = initialMenu
        refresh()
        showInterruptionIfNeeded()
        mainRunLoopDispatcher.dispatch { [weak self] in
            self?.showWelcomeIfNeeded()
        }
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let dispatcher = self.mainRunLoopDispatcher
            Task.detached { [weak self, agent, dispatcher] in
                _ = await agent.handleSleep()
                dispatcher.dispatch { [weak self] in
                    self?.refresh()
                }
            }
        }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.mainRunLoopDispatcher.dispatch { [weak self] in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func refresh() {
        refreshGeneration += 1
        let generation = refreshGeneration
        Task.detached { [weak self, agent] in
            let snapshot = await agent.advanceIfDue()
            let today = localDateString(Date())
            let summary = await agent.dailySummary(for: today)
            guard let self else { return }
            self.mainRunLoopDispatcher.dispatch { [weak self] in
                self?.applyRefresh(snapshot, summary: summary, generation: generation)
            }
        }
    }

    private func applyRefresh(
        _ snapshot: AgentSnapshot,
        summary: DailySummary,
        generation: Int
    ) {
        guard !isQuitting, generation == refreshGeneration else { return }
        if let instanceID = snapshot.agentInstanceID {
            lifecycleStore.markRunning(
                instanceID: instanceID, hasActiveSession: snapshot.agentState == .session)
        }
        guard !isMenuOpen else { return }
        let priorSnapshot = previousSnapshot
        deliverCompletionCue(from: priorSnapshot, to: snapshot)
        previousSnapshot = snapshot
        rebuildMenu(for: snapshot, summary: summary)
        if snapshot.agentState == .session, priorSnapshot?.agentState != .session {
            explainNotificationsIfNeeded()
            requestNotificationAuthorizationIfNeeded()
        }
    }

    private func rebuildMenu(for snapshot: AgentSnapshot, summary: DailySummary) {
        menuActionTargets.removeAll(keepingCapacity: true)
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
            item.button?.image = NSImage(
                systemSymbolName: missedAlert
                    ? "bell.badge"
                    : statusSymbol(for: snapshot),
                accessibilityDescription: missedAlert
                    ? "Pomo has a missed completion alert"
                    : "Pomo \(phase) \(state)")
            item.button?.title = formatRemaining(snapshot.remainingSeconds ?? 0)
            menu.addItem(withTitle: "\(phase) - \(state)", action: nil, keyEquivalent: "")
            menu.addItem(withTitle: rounds, action: nil, keyEquivalent: "")
            menu.addItem(.separator())
            if snapshot.sessionState == .running {
                addMenuAction(to: menu, title: "Pause") { [weak self] in self?.pauseSession() }
            } else if snapshot.sessionState == .paused {
                addMenuAction(to: menu, title: "Resume") { [weak self] in self?.resumeSession() }
            } else if snapshot.sessionState == .ready {
                addMenuAction(to: menu, title: "Start") { [weak self] in self?.resumeSession() }
            }
            addMenuAction(to: menu, title: "Skip") { [weak self] in self?.skipPhase() }
            addMenuAction(to: menu, title: "Stop Session") { [weak self] in
                self?.confirmStop()
            }
            menu.addItem(
                withTitle: "Next: \(nextPhaseDescription(for: snapshot))",
                action: nil,
                keyEquivalent: "")
            addSummaryItem(to: menu, summary: summary)
        } else {
            item.button?.title = ""
            item.button?.image = NSImage(
                systemSymbolName: missedAlert ? "bell.badge" : "target",
                accessibilityDescription: missedAlert
                    ? "Pomo has a missed completion alert"
                    : "Pomo Idle")
            addQuickStartItems(to: menu)
            addSummaryItem(to: menu, summary: summary)
        }
        if missedAlert {
            addMenuAction(to: menu, title: "Dismiss missed completion alert") { [weak self] in
                self?.dismissMissedAlert()
            }
        }
        menu.addItem(.separator())
        addMenuAction(to: menu, title: "Presets...", keyEquivalent: ",") { [weak self] in
            self?.openPresets()
        }
        addMenuAction(to: menu, title: "Alerts...") { [weak self] in self?.openAlerts() }
        let loginItem = addMenuAction(to: menu, title: "Launch at Login") { [weak self] in
            self?.toggleLaunchAtLogin()
        }
        switch SMAppService.mainApp.status {
        case .enabled: loginItem.state = .on
        case .requiresApproval: loginItem.state = .mixed
        default: loginItem.state = .off
        }
        addMenuAction(to: menu, title: "Quit Pomo", keyEquivalent: "q") { [weak self] in
            self?.quit()
        }
        menu.delegate = self
        item.menu = menu
    }

    private func addSummaryItem(to menu: NSMenu, summary: DailySummary) {
        menu.addItem(
            withTitle:
                "Today: \(summary.compactFocusText) Focus, \(summary.completedRounds) Rounds, "
                + "\(summary.currentStreak)-day streak",
            action: nil,
            keyEquivalent: "")
    }

    private func statusSymbol(for snapshot: AgentSnapshot) -> String {
        switch snapshot.sessionState {
        case .ready: return "play.circle"
        case .paused: return "pause.circle"
        case .running, .blocked, nil:
            return snapshot.phaseType == .focus ? "target" : "cup.and.saucer"
        }
    }

    private func nextPhaseDescription(for snapshot: AgentSnapshot) -> String {
        guard let configuration = snapshot.configuration else { return "Unavailable" }
        if snapshot.phaseType != .focus {
            return "Focus (\(formatRemaining(configuration.focusSeconds)))"
        }
        let nextCompletedRound = (snapshot.completedRounds ?? 0) + 1
        let isLongBreak = nextCompletedRound.isMultiple(of: configuration.longBreakEvery)
        let name = isLongBreak ? "Long Break" : "Short Break"
        let duration =
            isLongBreak
            ? configuration.longBreakSeconds : configuration.shortBreakSeconds
        return "\(name) (\(formatRemaining(duration)))"
    }

    fileprivate func showStatus() {
        item.button?.performClick(nil)
    }

    func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true
        guard missedAlert else { return }
        missedAlertGeneration += 1
        missedAlert = false
        alertPreferences.hasMissedAlert = false
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
        refresh()
    }

    @objc private func startClassic() {
        let dispatcher = mainRunLoopDispatcher
        Task.detached { [weak self, agent, dispatcher] in
            do {
                let snapshot = try await agent.startClassic()
                dispatcher.dispatch { [weak self] in
                    self?.sessionDidStart(snapshot)
                    self?.refresh()
                }
            } catch {
                dispatcher.dispatch { [weak self] in
                    self?.presentStartFailure(name: "Classic")
                    self?.refresh()
                }
            }
        }
    }

    private func addQuickStartItems(to menu: NSMenu) {
        guard let defaultPreset = try? presetStore.defaultPreset() else {
            addMenuAction(to: menu, title: "Start Classic") { [weak self] in
                self?.startClassic()
            }
            return
        }
        addStartPresetItem(defaultPreset, title: "Start \(defaultPreset.name)", to: menu)
        for preset in (try? presetStore.recentPresets()) ?? [] {
            addStartPresetItem(preset, title: preset.name, to: menu)
        }
        addMenuAction(to: menu, title: "Custom Session...") { [weak self] in
            self?.openCustomSession()
        }
    }

    @discardableResult
    private func addMenuAction(
        to menu: NSMenu,
        title: String,
        keyEquivalent: String = "",
        handler: @escaping @MainActor () -> Void
    ) -> NSMenuItem {
        let target = MenuActionTarget(handler: handler)
        menuActionTargets.append(target)
        let menuItem = menu.addItem(
            withTitle: title,
            action: #selector(MenuActionTarget.invokeMenuAction),
            keyEquivalent: keyEquivalent)
        menuItem.target = target
        return menuItem
    }

    private func addStartPresetItem(_ preset: Preset, title: String, to menu: NSMenu) {
        addMenuAction(to: menu, title: title) { [weak self] in
            self?.startPreset(id: preset.id, name: title)
        }
    }

    private func startPreset(id: UUID, name: String) {
        let dispatcher = mainRunLoopDispatcher
        Task.detached { [weak self, agent, dispatcher] in
            do {
                let snapshot = try await agent.start(presetID: id)
                dispatcher.dispatch { [weak self] in
                    self?.sessionDidStart(snapshot)
                    self?.refresh()
                }
            } catch {
                dispatcher.dispatch { [weak self] in
                    self?.presentStartFailure(name: name)
                    self?.refresh()
                }
            }
        }
    }

    private func presentStartFailure(name: String) {
        let alert = NSAlert()
        alert.messageText = "Unable to Start Session"
        alert.informativeText = "Pomo could not start \(name). Try again or reopen Pomo."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func openCustomSession() {
        if customSessionPopover == nil {
            customSessionPopover = CustomSessionPopoverController(
                agent: agent,
                store: presetStore,
                onStarted: { self.refresh() })
        }
        guard let button = item.button else { return }
        customSessionPopover?.show(relativeTo: button)
    }

    private func markLifecycle(for snapshot: AgentSnapshot) {
        guard let instanceID = snapshot.agentInstanceID else { return }
        lifecycleStore.markRunning(
            instanceID: instanceID, hasActiveSession: snapshot.agentState == .session)
    }

    private func sessionDidStart(_ snapshot: AgentSnapshot) {
        markLifecycle(for: snapshot)
        refresh()
    }

    @objc private func confirmStop() {
        let alert = NSAlert()
        alert.messageText = "Stop Session?"
        alert.informativeText = "Stopping now ends this Focus Phase."
        alert.addButton(withTitle: "Stop Session")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let dispatcher = mainRunLoopDispatcher
        Task.detached { [weak self, agent, dispatcher] in
            do {
                _ = try await agent.stopSession()
                dispatcher.dispatch { [weak self] in self?.refresh() }
            } catch {
                dispatcher.dispatch { [weak self] in
                    self?.presentActionFailure("Stop Session")
                    self?.refresh()
                }
            }
        }
    }

    @objc private func pauseSession() {
        let dispatcher = mainRunLoopDispatcher
        Task.detached { [weak self, agent, dispatcher] in
            do {
                _ = try await agent.pauseSession()
                dispatcher.dispatch { [weak self] in self?.refresh() }
            } catch {
                dispatcher.dispatch { [weak self] in
                    self?.presentActionFailure("Pause")
                    self?.refresh()
                }
            }
        }
    }

    @objc private func resumeSession() {
        let dispatcher = mainRunLoopDispatcher
        Task.detached { [weak self, agent, dispatcher] in
            do {
                _ = try await agent.resumeSession()
                dispatcher.dispatch { [weak self] in self?.refresh() }
            } catch {
                dispatcher.dispatch { [weak self] in
                    self?.presentActionFailure("Resume")
                    self?.refresh()
                }
            }
        }
    }

    @objc private func skipPhase() {
        let dispatcher = mainRunLoopDispatcher
        Task.detached { [weak self, agent, dispatcher] in
            do {
                _ = try await agent.skipPhase()
                dispatcher.dispatch { [weak self] in self?.refresh() }
            } catch {
                dispatcher.dispatch { [weak self] in
                    self?.presentActionFailure("Skip")
                    self?.refresh()
                }
            }
        }
    }

    private func presentActionFailure(_ action: String) {
        let alert = NSAlert()
        alert.messageText = "Unable to \(action)"
        alert.informativeText =
            "Pomo could not complete this action. Reopen the menu and try again."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func requestNotificationAuthorizationIfNeeded() {
        guard notificationsAvailable else { return }
        guard alertPreferences.preferences.notificationsEnabled else { return }
        guard !authorizationRequested else { return }
        authorizationRequested = true
        let dispatcher = mainRunLoopDispatcher
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]) { [weak self, dispatcher] _, _ in
                dispatcher.dispatch { [weak self] in
                    self?.refresh()
                }
            }
    }

    private func explainNotificationsIfNeeded() {
        guard !alertPreferences.hasShownNotificationExplanation else { return }
        guard !isExplainingNotifications else { return }
        isExplainingNotifications = true
        defer { isExplainingNotifications = false }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Completion Alerts"
        alert.informativeText =
            "Pomo can notify you when a Phase completes. You can change notifications and sound in Alerts."
        alert.addButton(withTitle: "Continue")
        alert.runModal()
        alertPreferences.hasShownNotificationExplanation = true
    }

    private func deliverCompletionCue(from previous: AgentSnapshot?, to current: AgentSnapshot) {
        guard notificationsAvailable else { return }
        guard let previous,
            previous.agentState == .session,
            previous.phaseType == .focus,
            previous.phaseID != current.phaseID
        else { return }
        let preferences = alertPreferences.preferences
        if preferences.soundEnabled { playCompletionChime() }
        guard preferences.notificationsEnabled else { return }
        let generation = missedAlertGeneration
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorization: AlertAuthorization
            switch settings.authorizationStatus {
            case .authorized: authorization = .authorized
            case .provisional: authorization = .provisional
            case .ephemeral: authorization = .ephemeral
            case .denied: authorization = .denied
            case .notDetermined: authorization = .notDetermined
            @unknown default: authorization = .denied
            }
            switch CompletionAlertDecision.resolve(
                notificationsEnabled: preferences.notificationsEnabled,
                authorization: authorization)
            {
            case .missed:
                self.mainRunLoopDispatcher.dispatch { [weak self] in
                    guard let self, generation == self.missedAlertGeneration else { return }
                    self.missedAlert = true
                    self.alertPreferences.hasMissedAlert = true
                    self.refresh()
                }
                return
            case .unavailable:
                return
            case .notify:
                break
            }
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
            if current.sessionState == .ready {
                content.categoryIdentifier = "POMO_PHASE"
            }
            let phaseID = current.phaseID ?? previous.phaseID ?? UUID()
            let request = UNNotificationRequest(
                identifier: "pomo-phase-\(phaseID.uuidString)",
                content: content,
                trigger: nil)
            UNUserNotificationCenter.current().add(request) { [weak self] error in
                guard error != nil else { return }
                self?.mainRunLoopDispatcher.dispatch { [weak self] in
                    guard generation == self?.missedAlertGeneration else { return }
                    self?.missedAlert = true
                    self?.alertPreferences.hasMissedAlert = true
                    self?.refresh()
                }
            }
        }
    }

    private func playCompletionChime() {
        NSSound(data: CompletionChime.data)?.play()
    }

    @objc private func dismissMissedAlert() {
        missedAlertGeneration += 1
        missedAlert = false
        alertPreferences.hasMissedAlert = false
        refresh()
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
        NSApp.activate(ignoringOtherApps: true)
        welcomePopover = WelcomePopoverController(
            onStart: { [weak self] launchAtLogin in
                guard let self else { return }
                self.alertPreferences.hasCompletedOnboarding = true
                self.registerLaunchAtLoginIfRequested(launchAtLogin)
                self.startClassic()
            },
            onAlerts: { [weak self] launchAtLogin in
                guard let self else { return }
                self.alertPreferences.hasCompletedOnboarding = true
                self.registerLaunchAtLoginIfRequested(launchAtLogin)
                self.openAlerts()
            },
            onLater: { [weak self] launchAtLogin in
                guard let self else { return }
                self.alertPreferences.hasCompletedOnboarding = true
                self.registerLaunchAtLoginIfRequested(launchAtLogin)
            })
        welcomePopover?.show(relativeTo: item.button)
    }

    @objc private func openAlerts() {
        guard notificationsAvailable else {
            let alert = NSAlert()
            alert.messageText = "Alerts Unavailable"
            alert.informativeText =
                "Notifications are available when Pomo runs as a bundled macOS app."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        let dispatcher = mainRunLoopDispatcher
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            dispatcher.dispatch { [weak self] in
                self?.presentAlerts(for: settings.authorizationStatus)
            }
        }
    }

    private func presentAlerts(for authorizationStatus: UNAuthorizationStatus) {
        let preferences = alertPreferences.preferences
        let alert = NSAlert()
        alert.messageText = "Alerts"
        let status: String
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: status = "Notifications are allowed."
        case .denied: status = "Notifications are denied. Open System Settings to allow them."
        case .notDetermined: status = "Notification permission has not been decided yet."
        @unknown default: status = "Notification permission status is unavailable."
        }
        alert.informativeText = "Choose which completion cues Pomo may use. \(status)"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Open System Settings")
        let notifications = NSButton(checkboxWithTitle: "Notifications", target: nil, action: nil)
        notifications.state = preferences.notificationsEnabled ? .on : .off
        let sound = NSButton(checkboxWithTitle: "Sound", target: nil, action: nil)
        sound.state = preferences.soundEnabled ? .on : .off
        let view = NSStackView(views: [notifications, sound])
        view.orientation = .vertical
        view.alignment = .leading
        view.spacing = 8
        alert.accessoryView = view
        let response = alert.runModal()
        if response == .alertThirdButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings") {
                NSWorkspace.shared.open(url)
            }
            return
        }
        guard response == .alertFirstButtonReturn else { return }
        alertPreferences.preferences = AlertPreferences(
            notificationsEnabled: notifications.state == .on,
            soundEnabled: sound.state == .on)
    }

    private func registerLaunchAtLoginIfRequested(_ requested: Bool) {
        guard requested else { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Launch at Login Unavailable"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            let status = SMAppService.mainApp.status
            if status == .requiresApproval {
                let alert = NSAlert()
                alert.messageText = "Approve Launch at Login"
                alert.informativeText =
                    "Open System Settings > General > Login Items and approve Pomo."
                alert.addButton(withTitle: "OK")
                alert.runModal()
                return
            }
            if status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            refresh()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Launch at Login Unavailable"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc private func quit() {
        guard !isQuitting else { return }
        let dispatcher = mainRunLoopDispatcher
        Task.detached { [weak self, agent, dispatcher] in
            let snapshot = await agent.snapshot()
            dispatcher.dispatch { [weak self] in
                self?.continueQuit(from: snapshot)
            }
        }
    }

    private func continueQuit(from snapshot: AgentSnapshot) {
        guard !isQuitting else { return }
        guard snapshot.agentState == .session else {
            finishQuit()
            return
        }
        let alert = NSAlert()
        alert.messageText = "Quit Pomo?"
        alert.informativeText =
            "The active Session will end and eligible partial Focus will be saved."
        alert.addButton(withTitle: "Quit and Save Focus")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let dispatcher = mainRunLoopDispatcher
        Task.detached { [weak self, agent, dispatcher] in
            do {
                _ = try await agent.stopSession()
                dispatcher.dispatch { [weak self] in self?.finishQuit() }
            } catch AgentCommandError.noActiveSession {
                dispatcher.dispatch { [weak self] in self?.finishQuit() }
            } catch {
                dispatcher.dispatch {
                    let failure = NSAlert()
                    failure.messageText = "Unable to Quit Safely"
                    failure.informativeText =
                        "Pomo could not save the active Focus. Resolve the issue before quitting."
                    failure.addButton(withTitle: "OK")
                    failure.runModal()
                }
            }
        }
    }

    private func finishQuit() {
        guard !isQuitting else { return }
        isQuitting = true
        refreshGeneration += 1
        refreshTimer?.invalidate()
        if let sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
        }
        let dispatcher = mainRunLoopDispatcher
        Task.detached { [agent, server, lifecycleStore, dispatcher] in
            let snapshot = await agent.snapshot()
            lifecycleStore.markCleanExit(
                instanceID: snapshot.agentInstanceID ?? UUID(),
                hasActiveSession: snapshot.agentState == .session)
            server.stop()
            dispatcher.dispatch {
                NSApp.terminate(nil)
            }
        }
    }

    private func showInterruptionIfNeeded() {
        guard let priorInterruption, priorInterruption.hadActiveSession else { return }
        let alert = NSAlert()
        alert.messageText = "Session interrupted"
        alert.informativeText = "The previous Session was lost when Pomo stopped unexpectedly."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func formatRemaining(_ seconds: Int) -> String {
        if seconds >= 3_600 {
            return String(
                format: "%d:%02d:%02d", seconds / 3_600, (seconds / 60) % 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private enum CompletionChime {
    static let data: Data = {
        let sampleRate = 44_100
        let sampleCount = Int(Double(sampleRate) * 0.24)
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)
        for index in 0..<sampleCount {
            let time = Double(index) / Double(sampleRate)
            let envelope = max(0, 1 - time / 0.24)
            let firstTone = sin(2 * Double.pi * 880 * time) * 0.25
            let secondTone = sin(2 * Double.pi * 1_320 * time) * 0.16
            samples.append(Int16((firstTone + secondTone) * envelope * Double(Int16.max)))
        }
        var bytes = Data()
        bytes.append(contentsOf: Array("RIFF".utf8))
        appendLittleEndian(UInt32(36 + samples.count * 2), to: &bytes)
        bytes.append(contentsOf: Array("WAVEfmt ".utf8))
        appendLittleEndian(UInt32(16), to: &bytes)
        appendLittleEndian(UInt16(1), to: &bytes)
        appendLittleEndian(UInt16(1), to: &bytes)
        appendLittleEndian(UInt32(sampleRate), to: &bytes)
        appendLittleEndian(UInt32(sampleRate * 2), to: &bytes)
        appendLittleEndian(UInt16(2), to: &bytes)
        appendLittleEndian(UInt16(16), to: &bytes)
        bytes.append(contentsOf: Array("data".utf8))
        appendLittleEndian(UInt32(samples.count * 2), to: &bytes)
        for sample in samples {
            appendLittleEndian(UInt16(bitPattern: sample), to: &bytes)
        }
        return bytes
    }()

    private static func appendLittleEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }
}

@MainActor
private final class PomoNotificationDelegate: NSObject,
    @preconcurrency UNUserNotificationCenterDelegate
{
    private let agent: PomoAgentCore
    private let openStatus: @MainActor () -> Void

    init(agent: PomoAgentCore, openStatus: @escaping @MainActor () -> Void) {
        self.agent = agent
        self.openStatus = openStatus
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "POMO_START_NEXT" {
            Task { @MainActor [agent] in
                let identifier = response.notification.request.identifier
                    .replacingOccurrences(of: "pomo-phase-", with: "")
                let snapshot = await agent.snapshot()
                if snapshot.sessionState == .ready,
                    snapshot.phaseID?.uuidString == identifier
                {
                    _ = try? await agent.resumeSession()
                }
                completionHandler()
            }
        } else {
            openStatus()
            NSApp.activate(ignoringOtherApps: true)
            completionHandler()
        }
    }
}
