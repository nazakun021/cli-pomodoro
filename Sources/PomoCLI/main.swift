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
            await writeInitialFollowEvent(json: json)
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

    private static func writeInitialFollowEvent(json: Bool) async {
        do {
            let event = try await LocalAgentClient(path: RuntimeEndpoint.socketPath())
                .followInitialEvent()
            if json {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys]
                FileHandle.standardOutput.write(try encoder.encode(event))
                FileHandle.standardOutput.write(Data("\n".utf8))
            } else if let snapshot = event.snapshot {
                let phase =
                    snapshot.phaseType?.rawValue.replacingOccurrences(of: "_", with: " ")
                    ?? "idle"
                let state = snapshot.sessionState?.rawValue ?? snapshot.agentState.rawValue
                let remaining = snapshot.remainingSeconds.map(String.init) ?? "-"
                print("Following \(phase) - \(state), \(remaining)s remaining.")
                print(
                    "Use `pomo pause`, `pomo resume`, `pomo skip`, or `pomo stop` in another terminal."
                )
            }
        } catch {
            FileHandle.standardError.write(Data("Pomo Agent is unavailable.\n".utf8))
            Foundation.exit(4)
        }
    }

    private static func runPlainSetup() async {
        let preset = await selectPreset() ?? .classic
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
            focus = prompt("Focus duration", current: focus)
            shortBreak = prompt("Short Break duration", current: shortBreak)
            longBreak = prompt("Long Break duration", current: longBreak)
            cadence = prompt("Long Break cadence", current: cadence)
            openEnded = promptBoolean("Open-ended", current: openEnded)
            if !openEnded {
                rounds = prompt("Rounds", current: rounds)
            }
            autoStartFocus = promptBoolean("Auto-start Focus", current: autoStartFocus)
            autoStartBreaks = promptBoolean("Auto-start Breaks", current: autoStartBreaks)
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
            guard let answer = readLine()?.lowercased(), answer == "y" || answer == "yes" else {
                print("Setup cancelled.")
                return
            }
            replace = true
        } else {
            replace = false
        }
        print("Start this Session? [y/N]", terminator: " ")
        guard let answer = readLine()?.lowercased(), answer == "y" || answer == "yes" else {
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

    private static func prompt(_ label: String, current: String) -> String {
        print("\(label) [\(current)]", terminator: " ")
        guard let value = readLine(), !value.isEmpty else { return current }
        return value
    }

    private static func promptBoolean(_ label: String, current: Bool) -> Bool {
        while true {
            let answer = prompt(label, current: current ? "y" : "n").lowercased()
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
