import Foundation
import PomoCore

@main
struct PomoCLI {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let json = arguments.contains("--json")
        let command = arguments.first(where: { !$0.hasPrefix("-") })

        guard command == "status" else {
            FileHandle.standardError.write(Data("Usage: pomo status [--json]\n".utf8))
            Foundation.exit(2)
        }

        let response = await statusResponse()
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            guard let data = try? encoder.encode(response) else {
                Foundation.exit(1)
            }
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
        } else {
            if let snapshot = response.snapshot {
                print("Pomo Agent is Idle (revision \(snapshot.revision)).")
            } else {
                print("Pomo Agent is not running.")
            }
        }
    }

    private static func statusResponse() async -> PublicResponse {
        (try? await LocalAgentClient(path: RuntimeEndpoint.socketPath()).status())
            ?? .agentNotRunning()
    }
}