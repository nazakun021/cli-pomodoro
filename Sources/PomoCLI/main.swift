import Foundation
import PomoCore

@main
struct PomoCLI {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let json = arguments.contains("--json")
        let command = arguments.first(where: { !$0.hasPrefix("-") })

        guard command == "status" || command == "start" || command == "stop" else {
            FileHandle.standardError.write(Data("Usage: pomo <status|start|stop> [--json]\n".utf8))
            Foundation.exit(2)
        }

        let response = await commandResponse(command: command!)
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            guard let data = try? encoder.encode(response) else {
                Foundation.exit(1)
            }
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
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

    private static func commandResponse(command: String) async -> PublicResponse {
        let client = LocalAgentClient(path: RuntimeEndpoint.socketPath())
        switch command {
        case "start":
            return (try? await client.startClassic())
                ?? .failure(
                    PublicError(
                        code: "agent_unavailable", message: "Pomo Agent is unavailable.",
                        exitCode: 4))
        case "stop":
            return (try? await client.stop())
                ?? .failure(
                    PublicError(
                        code: "invalid_state", message: "No active Session to stop.", exitCode: 3))
        default:
            return (try? await client.status()) ?? .agentNotRunning()
        }
    }
}
