import Foundation
import PomoCore

@main
struct PomoCLI {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let json = arguments.contains("--json")
        let replace = arguments.contains("--replace")
        let command = arguments.first(where: { !$0.hasPrefix("-") })

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

        let response = await commandResponse(command: command!, replace: replace)
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

    private static func commandResponse(command: String, replace: Bool) async -> PublicResponse {
        let client = LocalAgentClient(path: RuntimeEndpoint.socketPath())
        switch command {
        case "start":
            return (try? await client.startClassic(replace: replace))
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
}
