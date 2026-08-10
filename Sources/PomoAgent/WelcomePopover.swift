import AppKit

@MainActor
final class WelcomePopoverController: NSObject {
    private let popover = NSPopover()

    init(
        onStart: @escaping @MainActor (Bool) -> Void,
        onAlerts: @escaping @MainActor (Bool) -> Void,
        onLater: @escaping @MainActor (Bool) -> Void
    ) {
        super.init()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 230)
        popover.contentViewController = WelcomeViewController(
            onStart: { [weak self] launchAtLogin in
                self?.popover.close()
                onStart(launchAtLogin)
            },
            onAlerts: { [weak self] launchAtLogin in
                self?.popover.close()
                onAlerts(launchAtLogin)
            },
            onLater: { [weak self] launchAtLogin in
                self?.popover.close()
                onLater(launchAtLogin)
            })
    }

    func show(relativeTo button: NSStatusBarButton) {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

@MainActor
private final class WelcomeViewController: NSViewController {
    private let launchAtLogin = NSButton(
        checkboxWithTitle: "Launch at Login (off by default)", target: nil, action: nil)
    private let onStart: @MainActor (Bool) -> Void
    private let onAlerts: @MainActor (Bool) -> Void
    private let onLater: @MainActor (Bool) -> Void

    init(
        onStart: @escaping @MainActor (Bool) -> Void,
        onAlerts: @escaping @MainActor (Bool) -> Void,
        onLater: @escaping @MainActor (Bool) -> Void
    ) {
        self.onStart = onStart
        self.onAlerts = onAlerts
        self.onLater = onLater
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let title = NSTextField(labelWithString: "Welcome to Pomo")
        title.font = .boldSystemFont(ofSize: 16)
        let detail = NSTextField(
            wrappingLabelWithString: "Pomo lives in the menu bar. Classic uses 25-minute Focus, 5-minute Short Break, and 15-minute Long Break phases.")
        detail.maximumNumberOfLines = 0
        detail.lineBreakMode = .byWordWrapping
        launchAtLogin.target = self
        let start = NSButton(title: "Start Classic", target: self, action: #selector(start))
        start.keyEquivalent = "\r"
        let alerts = NSButton(title: "Open Alerts", target: self, action: #selector(alerts))
        let later = NSButton(title: "Later", target: self, action: #selector(later))
        let actions = NSStackView(views: [start, alerts, later])
        actions.orientation = .horizontal
        actions.distribution = .fillEqually
        actions.spacing = 8
        let stack = NSStackView(views: [title, detail, launchAtLogin, actions])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        view = NSView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func start() {
        onStart(launchAtLogin.state == .on)
    }

    @objc private func alerts() {
        onAlerts(launchAtLogin.state == .on)
    }

    @objc private func later() {
        onLater(launchAtLogin.state == .on)
    }
}
