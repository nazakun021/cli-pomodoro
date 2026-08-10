import Darwin
import Foundation
import PomoCore

@main
struct PomoCLI {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let json = arguments.contains("--json")
        let replace = arguments.contains("--replace")
        let command = arguments.first(where: { !$0.hasPrefix("-") })
        let startConfiguration: SessionConfiguration?

        guard command != nil else {
            guard !json, isatty(STDIN_FILENO) != 0, isatty(STDOUT_FILENO) != 0 else {
                writeInteractiveUsageError(json: json)
                Foundation.exit(2)
            }
            guard !replace else {
                FileHandle.standardError.write(
                    Data("`--replace` is available only with `pomo start`.\n".utf8))
                Foundation.exit(2)
            }
            await runPlainSetup()
            return
        }

        if command == "start" {
            do { startConfiguration = try parseStartConfiguration(arguments) } catch {
                FileHandle.standardError.write(Data("Invalid start options.\n".utf8))
                Foundation.exit(2)
            }
        } else {
            startConfiguration = nil
        }

        guard
            command == "status" || command == "start" || command == "stop"
                || command == "pause" || command == "resume" || command == "skip"
                || command == "follow",
            !replace || command == "start"
        else {
            FileHandle.standardError.write(
                Data(
                    "Usage: pomo <status|start|stop|pause|resume|skip> [--json] [--replace]\n".utf8)
            )
            Foundation.exit(2)
        }

        if command == "follow" {
            await follow(json: json)
            return
        }

        let response = await commandResponse(
            command: command!, replace: replace, configuration: startConfiguration)
        write(response, json: json)
        if !response.ok {
            Foundation.exit(Int32(response.error?.exitCode ?? 1))
        }
    }

    private static func writeInteractiveUsageError(json: Bool) {
        if json {
            let response = PublicResponse.failure(
                PublicError(
                    code: "usage",
                    message:
                        "Interactive setup requires a terminal. Use `pomo start 25m` for a direct start.",
                    exitCode: 2),
                command: "interactive")
            write(response, json: true)
        } else {
            FileHandle.standardError.write(
                Data(
                    "Interactive setup requires a terminal. Use `pomo start 25m` or `pomo start 25m --json`.\n"
                        .utf8)
            )
        }
    }

    private static func follow(json: Bool) async {
        do {
            let events = try await LocalAgentClient(path: RuntimeEndpoint.socketPath())
                .followEvents()
            if !json {
                await followHuman(events)
                return
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            for try await event in events {
                FileHandle.standardOutput.write(try encoder.encode(event))
                FileHandle.standardOutput.write(Data("\n".utf8))
            }
        } catch {
            FileHandle.standardError.write(Data("Pomo Agent is unavailable.\n".utf8))
            Foundation.exit(4)
        }
    }

    private static func followHuman(
        _ events: AsyncThrowingStream<FollowEvent, Error>
    ) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    for try await event in events {
                        guard let snapshot = event.snapshot else { continue }
                        let phase =
                            snapshot.phaseType?.rawValue
                            .replacingOccurrences(of: "_", with: " ") ?? "idle"
                        let state = snapshot.sessionState?.rawValue ?? snapshot.agentState.rawValue
                        let remaining = snapshot.remainingSeconds.map(String.init) ?? "-"
                        let rounds = snapshot.completedRounds.map(String.init) ?? "-"
                        let next: String
                        if snapshot.agentState != .session {
                            next = "-"
                        } else if snapshot.phaseType == .focus,
                            let target = snapshot.configuration?.targetRounds,
                            let completed = snapshot.completedRounds,
                            completed + 1 >= target
                        {
                            next = "End Session"
                        } else {
                            next = snapshot.phaseType == .focus ? "Short Break" : "Focus"
                        }
                        print(
                            "Follow #\(event.sequence): \(phase) - \(state), \(remaining)s remaining, rounds \(rounds), next \(next)."
                        )
                        if event.sequence == 0 {
                            print(
                                "Controls: use `pomo pause`, `pomo resume`, `pomo skip`, or `pomo stop` in another terminal."
                            )
                        }
                    }
                } catch is CancellationError {
                } catch {
                    FileHandle.standardError.write(
                        Data("Pomo Agent is unavailable.\n".utf8))
                    Foundation.exit(4)
                }
            }
            group.addTask {
                await waitForFollowExitKey()
            }
            await group.next()
            group.cancelAll()
        }
    }

    private static func waitForFollowExitKey() async {
        guard isatty(STDIN_FILENO) != 0 else {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
            }
            return
        }
        var terminal = termios()
        guard tcgetattr(STDIN_FILENO, &terminal) == 0 else { return }
        let original = terminal
        terminal.c_lflag &= ~(UInt(ECHO) | UInt(ICANON) | UInt(ISIG))
        terminal.c_cc.0 = 0
        terminal.c_cc.1 = 0
        guard tcsetattr(STDIN_FILENO, TCSANOW, &terminal) == 0 else { return }
        defer {
            var restored = original
            _ = tcsetattr(STDIN_FILENO, TCSANOW, &restored)
        }

        var byte: UInt8 = 0
        while !Task.isCancelled {
            var descriptor = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
            guard poll(&descriptor, 1, 100) >= 0 else { return }
            guard descriptor.revents & Int16(POLLIN) != 0 else { continue }
            guard read(STDIN_FILENO, &byte, 1) == 1 else { return }
            if byte == 3 || byte == 27 || byte == 113 || byte == 81 { return }
        }
    }

    private static func runPlainSetup() async {
        guard let preset = await selectPreset() else {
            print("Setup cancelled.")
            return
        }
        var focus = "\(preset.configuration.focusSeconds)s"
        var shortBreak = "\(preset.configuration.shortBreakSeconds)s"
        var longBreak = "\(preset.configuration.longBreakSeconds)s"
        var cadence = "\(preset.configuration.longBreakEvery)"
        var rounds = preset.configuration.targetRounds.map(String.init) ?? ""
        var openEnded = preset.configuration.openEnded
        var autoStartFocus = preset.configuration.autoStartFocus
        var autoStartBreaks = preset.configuration.autoStartBreaks

        let configuration: SessionConfiguration
        while true {
            print("Pomo setup")
            print("Preset: \(preset.name) (customize values below; press Enter to keep a value)")
            guard let value = prompt("Focus duration", current: focus) else {
                print("Setup cancelled.")
                return
            }
            focus = value
            guard let value = prompt("Short Break duration", current: shortBreak) else {
                print("Setup cancelled.")
                return
            }
            shortBreak = value
            guard let value = prompt("Long Break duration", current: longBreak) else {
                print("Setup cancelled.")
                return
            }
            longBreak = value
            guard let value = prompt("Long Break cadence", current: cadence) else {
                print("Setup cancelled.")
                return
            }
            cadence = value
            guard let value = promptBoolean("Open-ended", current: openEnded) else {
                print("Setup cancelled.")
                return
            }
            openEnded = value
            if !openEnded {
                guard let value = prompt("Rounds", current: rounds) else {
                    print("Setup cancelled.")
                    return
                }
                rounds = value
            }
            guard let value = promptBoolean("Auto-start Focus", current: autoStartFocus) else {
                print("Setup cancelled.")
                return
            }
            autoStartFocus = value
            guard let value = promptBoolean("Auto-start Breaks", current: autoStartBreaks) else {
                print("Setup cancelled.")
                return
            }
            autoStartBreaks = value
            do {
                configuration = try PresetConfigurationDraft(
                    focus: focus, shortBreak: shortBreak, longBreak: longBreak,
                    longBreakEvery: cadence, rounds: rounds, openEnded: openEnded,
                    autoStartFocus: autoStartFocus, autoStartBreaks: autoStartBreaks
                ).configuration()
                break
            } catch {
                print(
                    "Check the highlighted value format and try again. Your entries are retained.")
            }
        }

        print("Pomo setup")
        print("Review: \(preset.name) with one-session overrides")
        print(
            "Focus: \(configuration.focusSeconds)s | Short Break: \(configuration.shortBreakSeconds)s | Long Break: \(configuration.longBreakSeconds)s"
        )
        print(
            "Rounds: \(configuration.targetRounds ?? 0) | Auto-start Focus: \(configuration.autoStartFocus ? "on" : "off") | Auto-start Breaks: \(configuration.autoStartBreaks ? "on" : "off")"
        )
        let status = await commandResponse(command: "status", replace: false, configuration: nil)
        let replace: Bool
        if status.data?.agentState == .session {
            print("An active Session will be replaced. Continue? [y/N]", terminator: " ")
            guard let answer = readLine()?.lowercased(),
                answer == "y" || answer == "yes"
            else {
                print("Setup cancelled.")
                return
            }
            replace = true
        } else {
            replace = false
        }
        print("Start this Session? [y/N]", terminator: " ")
        guard let answer = readLine()?.lowercased(),
            answer == "y" || answer == "yes"
        else {
            print("Setup cancelled.")
            return
        }
        let response = await commandResponse(
            command: "start", replace: replace, configuration: configuration)
        write(response, json: false)
        if !response.ok {
            Foundation.exit(Int32(response.error?.exitCode ?? 1))
        }
    }

    private static func selectPreset() async -> Preset? {
        guard
            let discovery = try? await LocalAgentClient(path: RuntimeEndpoint.socketPath())
                .presetDiscovery()
        else { return .classic }
        var choices = [discovery.defaultPreset] + discovery.recentPresets
        choices += discovery.presets.filter { preset in
            !choices.contains(where: { $0.id == preset.id })
        }
        print("Choose a Preset:")
        for (index, preset) in choices.enumerated() {
            let marker = preset.id == discovery.defaultPreset.id ? " (default)" : ""
            print("\(index + 1). \(preset.name)\(marker)")
        }
        print("Preset [1]", terminator: " ")
        guard let input = readLine(), !input.isEmpty else { return choices.first }
        guard let index = Int(input), choices.indices.contains(index - 1) else {
            print("Invalid Preset selection. Using the default.")
            return choices.first
        }
        return choices[index - 1]
    }

    private static func prompt(_ label: String, current: String) -> String? {
        print("\(label) [\(current)]", terminator: " ")
        guard let value = readLine() else { return nil }
        guard !value.isEmpty else { return current }
        return value
    }

    private static func promptBoolean(_ label: String, current: Bool) -> Bool? {
        while true {
            guard let value = prompt(label, current: current ? "y" : "n") else { return nil }
            let answer = value.lowercased()
            switch answer {
            case "y", "yes": return true
            case "n", "no": return false
            default: print("Enter y or n.")
            }
        }
    }

    private static func write(_ response: PublicResponse, json: Bool) {
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            guard let data = try? encoder.encode(response) else {
                Foundation.exit(1)
            }
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
        } else if !response.ok, let error = response.error {
            FileHandle.standardError.write(Data("\(error.message)\n".utf8))
        } else {
            if let snapshot = response.data, snapshot.agentState == .session {
                print("Classic Focus started (revision \(snapshot.revision)).")
            } else if let snapshot = response.data, snapshot.agentRunning {
                print("Pomo Agent is Idle (revision \(snapshot.revision)).")
            } else {
                print("Pomo Agent is not running.")
            }
        }
    }

    private static func commandResponse(
        command: String,
        replace: Bool,
        configuration: SessionConfiguration?
    ) async -> PublicResponse {
        let client = LocalAgentClient(path: RuntimeEndpoint.socketPath())
        switch command {
        case "start":
            await launchAgentIfNeeded()
            let response: PublicResponse?
            if let configuration {
                response = try? await client.start(configuration: configuration, replace: replace)
            } else {
                response = try? await client.startClassic(replace: replace)
            }
            return response
                ?? .failure(
                    PublicError(
                        code: "agent_unavailable", message: "Pomo Agent is unavailable.",
                        exitCode: 4),
                    command: "start")
        case "stop":
            return (try? await client.stop())
                ?? .failure(
                    PublicError(
                        code: "invalid_state", message: "No active Session to stop.", exitCode: 3))
        case "pause":
            return (try? await client.pause())
                ?? .failure(
                    PublicError(
                        code: "agent_unavailable", message: "Pomo Agent is unavailable.",
                        exitCode: 4),
                    command: "pause")
        case "resume":
            return (try? await client.resume())
                ?? .failure(
                    PublicError(
                        code: "agent_unavailable", message: "Pomo Agent is unavailable.",
                        exitCode: 4),
                    command: "resume")
        case "skip":
            return (try? await client.skip())
                ?? .failure(
                    PublicError(
                        code: "agent_unavailable", message: "Pomo Agent is unavailable.",
                        exitCode: 4),
                    command: "skip")
        default:
            return (try? await client.status()) ?? .agentNotRunning()
        }
    }

    private static func launchAgentIfNeeded() async {
        let socketPath = RuntimeEndpoint.socketPath()
        if (try? await LocalAgentClient(path: socketPath).status()) != nil { return }
        let candidates = [
            "/Applications/Pomo.app",
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications/Pomo.app").path,
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".build/release/Pomo.app").path,
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".build/arm64-apple-macosx/release/Pomo.app").path,
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".build/x86_64-apple-macosx/release/Pomo.app").path,
        ]
        guard
            let appPath = candidates.first(where: {
                FileManager.default.fileExists(atPath: $0)
            })
        else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appPath, "--background"]
        guard (try? process.run()) != nil else { return }
        for _ in 0..<30 {
            guard !FileManager.default.fileExists(atPath: socketPath) else { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    private static func parseStartConfiguration(_ arguments: [String]) throws
        -> SessionConfiguration?
    {
        let startIndex = arguments.firstIndex(of: "start")!
        let values = Array(arguments.dropFirst(startIndex + 1))
        var focus: Int?
        var shortBreak: Int?
        var longBreak: Int?
        var rounds: Int?
        var openEnded = false
        var cadence: Int?
        var autoFocus: Bool?
        var autoBreaks: Bool?
        var positional: String?
        var index = 0

        while index < values.count {
            let value = values[index]
            if value == "--replace" || value == "--json" {
                index += 1
                continue
            }
            if value == "--open-ended" {
                openEnded = true
                index += 1
                continue
            }
            if value == "--auto-start-focus" {
                autoFocus = true
                index += 1
                continue
            }
            if value == "--no-auto-start-focus" {
                autoFocus = false
                index += 1
                continue
            }
            if value == "--auto-start-breaks" {
                autoBreaks = true
                index += 1
                continue
            }
            if value == "--no-auto-start-breaks" {
                autoBreaks = false
                index += 1
                continue
            }
            guard index + 1 < values.count else { throw DurationParserError.invalidDuration }
            let next = values[index + 1]
            switch value {
            case "--focus": focus = try DurationParser.parse(next)
            case "--short-break": shortBreak = try DurationParser.parse(next)
            case "--long-break": longBreak = try DurationParser.parse(next)
            case "--rounds": rounds = Int(next)
            case "--long-break-every": cadence = Int(next)
            default:
                guard positional == nil else { throw DurationParserError.invalidDuration }
                positional = value
                index += 1
                continue
            }
            index += 2
        }

        guard positional == nil || focus == nil else { throw DurationParserError.invalidDuration }
        if let positional { focus = try DurationParser.parse(positional) }
        guard !openEnded || rounds == nil else { throw DurationParserError.invalidDuration }
        guard
            focus != nil || shortBreak != nil || longBreak != nil || rounds != nil || openEnded
                || cadence != nil || autoFocus != nil || autoBreaks != nil
        else { return nil }
        let classic = SessionConfiguration.classic
        return try SessionConfiguration(
            focusSeconds: focus ?? classic.focusSeconds,
            shortBreakSeconds: shortBreak ?? classic.shortBreakSeconds,
            longBreakSeconds: longBreak ?? classic.longBreakSeconds,
            longBreakEvery: cadence ?? classic.longBreakEvery,
            openEnded: openEnded,
            targetRounds: openEnded ? nil : (rounds ?? classic.targetRounds),
            autoStartFocus: autoFocus ?? classic.autoStartFocus,
            autoStartBreaks: autoBreaks ?? classic.autoStartBreaks)
    }
}
