import AppKit
import PomoCore

@main
struct PomoAgent {
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)

        let agent = PomoAgentCore(productVersion: "0.1.0")
        guard let socketPath = try? RuntimeEndpoint.prepare(),
            let server = try? LocalAgentServer(path: socketPath, agent: agent)
        else {
            return
        }
        let statusItem = IdleStatusItem(agent: agent, server: server)
        withExtendedLifetime(statusItem) {
            application.run()
        }
    }
}

@MainActor
private final class IdleStatusItem: NSObject {
    private let agent: PomoAgentCore
    private let server: LocalAgentServer
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var refreshTimer: Timer?

    init(agent: PomoAgentCore, server: LocalAgentServer) {
        self.agent = agent
        self.server = server
        super.init()
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    private func refresh() {
        Task { [weak self] in
            guard let self else { return }
            let snapshot = await agent.snapshot()
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
            let pause = menu.addItem(withTitle: "Pause", action: nil, keyEquivalent: "")
            pause.isEnabled = false
            let skip = menu.addItem(withTitle: "Skip", action: nil, keyEquivalent: "")
            skip.isEnabled = false
            menu.addItem(
                withTitle: "Stop Session", action: #selector(confirmStop), keyEquivalent: "")
            menu.items.last?.target = self
            menu.addItem(withTitle: "Next: \(nextPhase)", action: nil, keyEquivalent: "")
        } else {
            item.button?.title = ""
            item.button?.image = NSImage(
                systemSymbolName: "timer", accessibilityDescription: "Pomo Idle")
            menu.addItem(withTitle: "No Session", action: nil, keyEquivalent: "")
            menu.addItem(
                withTitle: "Start Classic", action: #selector(startClassic), keyEquivalent: "")
            menu.items.last?.target = self
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Pomo", action: #selector(quit), keyEquivalent: "q")
        menu.items.last?.target = self
        item.menu = menu
    }

    @objc private func startClassic() {
        Task { [agent] in
            _ = try? await agent.startClassic()
            refresh()
        }
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

    @objc private func quit() {
        refreshTimer?.invalidate()
        server.stop()
        NSApp.terminate(nil)
    }

    private func formatRemaining(_ seconds: Int) -> String {
        if seconds >= 3_600 {
            return String(format: "%d:%02d:%02d", seconds / 3_600, (seconds / 60) % 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
