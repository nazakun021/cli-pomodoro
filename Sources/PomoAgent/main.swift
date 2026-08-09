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
        let statusItem = IdleStatusItem(server: server)
        withExtendedLifetime(statusItem) {
            application.run()
        }
    }
}

@MainActor
private final class IdleStatusItem: NSObject {
    private let server: LocalAgentServer
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    init(server: LocalAgentServer) {
        self.server = server
        super.init()
        item.button?.image = NSImage(
            systemSymbolName: "timer", accessibilityDescription: "Pomo Idle")
        let menu = NSMenu()
        menu.addItem(withTitle: "No Session", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Pomo", action: #selector(quit), keyEquivalent: "q")
        menu.items.last?.target = self
        item.menu = menu
    }

    @objc private func quit() {
        server.stop()
        NSApp.terminate(nil)
    }
}
