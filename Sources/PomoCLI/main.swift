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
            if json {
                let response = PublicResponse.failure(
                    PublicError(
                        code: "usage",
                        message:
                            "Interactive setup requires a terminal. Use `pomo start 25m` for a direct start.",
                        exitCode: 2),
                    command: "interactive")
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys]
                if let data = try? encoder.encode(response) {
                    FileHandle.standardOutput.write(data)
                    FileHandle.standardOutput.write(Data("\n".utf8))
                }
            } else {
                FileHandle.standardError.write(
                    Data(
                        "Interactive setup requires a terminal. Use `pomo start 25m` or `pomo start 25m --json`.\n"
                            .utf8)
                )
            }
            Foundation.exit(2)
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
                || command == "pause" || command == "resume" || command == "skip",
            !replace || command == "start"
        else {
            FileHandle.standardError.write(
                Data(
                    "Usage: pomo <status|start|stop|pause|resume|skip> [--json] [--replace]\n".utf8)
            )
            Foundation.exit(2)
        }

        let response = await commandResponse(
            command: command!, replace: replace, configuration: startConfiguration)
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
        if !response.ok {
            Foundation.exit(Int32(response.error?.exitCode ?? 1))
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
