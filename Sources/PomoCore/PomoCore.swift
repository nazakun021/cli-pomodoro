import Darwin
import Foundation

public enum AgentState: String, Codable, Sendable {
    case idle
    case recovery
}

public struct AgentSnapshot: Codable, Equatable, Sendable {
    public let agentRunning: Bool
    public let agentInstanceID: UUID
    public let agentState: AgentState
    public let revision: UInt64
    public let session: SessionSnapshot?
    public let recovery: RecoverySnapshot?

    public init(
        agentRunning: Bool,
        agentInstanceID: UUID,
        agentState: AgentState,
        revision: UInt64,
        session: SessionSnapshot? = nil,
        recovery: RecoverySnapshot? = nil
    ) {
        self.agentRunning = agentRunning
        self.agentInstanceID = agentInstanceID
        self.agentState = agentState
        self.revision = revision
        self.session = session
        self.recovery = recovery
    }

    enum CodingKeys: String, CodingKey {
        case agentRunning = "agent_running"
        case agentInstanceID = "agent_instance_id"
        case agentState = "agent_state"
        case revision = "state_revision"
        case sessionID = "session_id"
        case sessionState = "session_state"
        case phaseID = "phase_id"
        case phaseType = "phase_type"
        case sourcePresetName = "source_preset_name"
        case configuration
        case completedRounds = "completed_rounds"
        case configuredDurationSeconds = "configured_duration_seconds"
        case remainingSeconds = "remaining_seconds"
        case sessionStartedAt = "session_started_at"
        case phaseStartedAt = "phase_started_at"
        case expectedTransitionAt = "expected_transition_at"
        case recovery
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(agentRunning, forKey: .agentRunning)
        try container.encode(agentInstanceID, forKey: .agentInstanceID)
        try container.encode(agentState, forKey: .agentState)
        try container.encode(revision, forKey: .revision)
        try container.encodeNil(forKey: .sessionID)
        try container.encodeNil(forKey: .sessionState)
        try container.encodeNil(forKey: .phaseID)
        try container.encodeNil(forKey: .phaseType)
        try container.encodeNil(forKey: .sourcePresetName)
        try container.encodeNil(forKey: .configuration)
        try container.encodeNil(forKey: .completedRounds)
        try container.encodeNil(forKey: .configuredDurationSeconds)
        try container.encodeNil(forKey: .remainingSeconds)
        try container.encodeNil(forKey: .sessionStartedAt)
        try container.encodeNil(forKey: .phaseStartedAt)
        try container.encodeNil(forKey: .expectedTransitionAt)
        try container.encodeNil(forKey: .recovery)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            agentRunning: try container.decode(Bool.self, forKey: .agentRunning),
            agentInstanceID: try container.decode(UUID.self, forKey: .agentInstanceID),
            agentState: try container.decode(AgentState.self, forKey: .agentState),
            revision: try container.decode(UInt64.self, forKey: .revision)
        )
    }
}

public struct SessionSnapshot: Codable, Equatable, Sendable {
    public init() {}
}

public struct RecoverySnapshot: Codable, Equatable, Sendable {
    public init() {}
}

public struct PublicResponse: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let success: Bool
    public let agentRunning: Bool
    public let snapshot: AgentSnapshot?
    public let error: PublicError?

    public static func success(snapshot: AgentSnapshot) -> PublicResponse {
        PublicResponse(
            schemaVersion: 1, success: true, agentRunning: true, snapshot: snapshot, error: nil)
    }

    public static func agentNotRunning() -> PublicResponse {
        PublicResponse(
            schemaVersion: 1, success: true, agentRunning: false, snapshot: nil, error: nil)
    }

    public static func failure(_ error: PublicError) -> PublicResponse {
        PublicResponse(
            schemaVersion: 1, success: false, agentRunning: false, snapshot: nil, error: error)
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case success
        case agentRunning = "agent_running"
        case snapshot
        case error
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(success, forKey: .success)
        try container.encode(agentRunning, forKey: .agentRunning)
        try container.encodeIfPresent(snapshot, forKey: .snapshot)
        if snapshot == nil { try container.encodeNil(forKey: .snapshot) }
        try container.encodeIfPresent(error, forKey: .error)
        if error == nil { try container.encodeNil(forKey: .error) }
    }
}

public struct PublicError: Codable, Equatable, Sendable {
    public let code: String
    public let message: String
    public let exitCode: Int

    public init(code: String, message: String, exitCode: Int) {
        self.code = code
        self.message = message
        self.exitCode = exitCode
    }

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case exitCode = "exit_code"
    }
}

public enum FrameCodecError: Error, Equatable, Sendable {
    case emptyPayload
    case oversizedPayload
    case truncatedFrame
    case lengthMismatch
}

public enum FrameCodec {
    public static let maximumPayloadLength = 1_048_576

    public static func encode(_ payload: Data) throws -> Data {
        guard !payload.isEmpty else { throw FrameCodecError.emptyPayload }
        guard payload.count <= maximumPayloadLength else { throw FrameCodecError.oversizedPayload }

        var length = UInt32(payload.count).bigEndian
        var frame = Data(bytes: &length, count: MemoryLayout<UInt32>.size)
        frame.append(payload)
        return frame
    }

    public static func decode(_ frame: Data) throws -> Data {
        guard frame.count >= MemoryLayout<UInt32>.size else { throw FrameCodecError.truncatedFrame }
        let length = frame.prefix(MemoryLayout<UInt32>.size).withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self).bigEndian
        }
        guard length > 0 else { throw FrameCodecError.emptyPayload }
        guard length <= maximumPayloadLength else { throw FrameCodecError.oversizedPayload }

        let payload = frame.dropFirst(MemoryLayout<UInt32>.size)
        guard payload.count == Int(length) else { throw FrameCodecError.lengthMismatch }
        return Data(payload)
    }
}

public struct ProtocolVersion: Codable, Equatable, Sendable {
    public let major: Int
    public let minor: Int

    public init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }
}

public struct ProtocolRange: Codable, Equatable, Sendable {
    public let major: Int
    public let minimumMinor: Int
    public let maximumMinor: Int

    public init(major: Int, minimumMinor: Int, maximumMinor: Int) {
        self.major = major
        self.minimumMinor = minimumMinor
        self.maximumMinor = maximumMinor
    }
}

public struct ProtocolNegotiation: Equatable, Sendable {
    public let version: ProtocolVersion
    public let capabilities: [String]
}

public enum ProtocolNegotiationError: Error, Equatable, Sendable {
    case invalidRange
    case majorMismatch
    case noSharedMinor
}

public enum ProtocolNegotiator {
    public static func negotiate(
        agent: ProtocolRange,
        client: ProtocolRange,
        agentCapabilities: [String],
        clientCapabilities: [String]
    ) throws -> ProtocolNegotiation {
        guard agent.minimumMinor <= agent.maximumMinor,
            client.minimumMinor <= client.maximumMinor
        else { throw ProtocolNegotiationError.invalidRange }
        guard agent.major == client.major else { throw ProtocolNegotiationError.majorMismatch }

        let minimum = max(agent.minimumMinor, client.minimumMinor)
        let maximum = min(agent.maximumMinor, client.maximumMinor)
        guard minimum <= maximum else { throw ProtocolNegotiationError.noSharedMinor }

        let clientCapabilitySet = Set(clientCapabilities)
        let capabilities = Array(Set(agentCapabilities).intersection(clientCapabilitySet)).sorted()
        return ProtocolNegotiation(
            version: ProtocolVersion(major: agent.major, minor: maximum),
            capabilities: capabilities
        )
    }
}

public enum LocalAgentTransportError: Error, Equatable, Sendable {
    case invalidPath
    case socketCreationFailed
    case bindFailed
    case listenFailed
    case connectFailed
    case malformedRequest
    case readFailed
    case writeFailed
    case invalidResponse
    case protocolMismatch
    case runtimeDirectoryFailed
    case insecureRuntimeDirectory
}

public struct IPCCommand: Codable, Equatable, Sendable {
    public let name: String
    public let arguments: EmptyArguments

    public init(name: String) {
        self.name = name
        arguments = EmptyArguments()
    }
}

public struct EmptyArguments: Codable, Equatable, Sendable {
    public init() {}
}

public struct IPCRequest: Codable, Equatable, Sendable {
    public let messageType: String
    public let protocolVersion: ProtocolVersion
    public let requestID: UUID
    public let agentInstanceID: UUID
    public let issuedAt: String
    public let command: IPCCommand

    public init(
        protocolVersion: ProtocolVersion,
        requestID: UUID,
        agentInstanceID: UUID,
        issuedAt: String,
        command: IPCCommand
    ) {
        messageType = "request"
        self.protocolVersion = protocolVersion
        self.requestID = requestID
        self.agentInstanceID = agentInstanceID
        self.issuedAt = issuedAt
        self.command = command
    }

    enum CodingKeys: String, CodingKey {
        case messageType = "message_type"
        case protocolVersion = "protocol_version"
        case requestID = "request_id"
        case agentInstanceID = "agent_instance_id"
        case issuedAt = "issued_at"
        case command
    }
}

public struct IPCResponse: Codable, Equatable, Sendable {
    public let messageType: String
    public let protocolVersion: ProtocolVersion
    public let requestID: UUID
    public let ok: Bool
    public let stateRevision: UInt64
    public let result: AgentSnapshot?
    public let error: PublicError?

    public init(
        protocolVersion: ProtocolVersion,
        requestID: UUID,
        stateRevision: UInt64,
        result: AgentSnapshot
    ) {
        messageType = "response"
        self.protocolVersion = protocolVersion
        self.requestID = requestID
        ok = true
        self.stateRevision = stateRevision
        self.result = result
        error = nil
    }

    enum CodingKeys: String, CodingKey {
        case messageType = "message_type"
        case protocolVersion = "protocol_version"
        case requestID = "request_id"
        case ok
        case stateRevision = "state_revision"
        case result
        case error
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageType, forKey: .messageType)
        try container.encode(protocolVersion, forKey: .protocolVersion)
        try container.encode(requestID, forKey: .requestID)
        try container.encode(ok, forKey: .ok)
        try container.encode(stateRevision, forKey: .stateRevision)
        try container.encodeIfPresent(result, forKey: .result)
        if result == nil { try container.encodeNil(forKey: .result) }
        try container.encodeIfPresent(error, forKey: .error)
        if error == nil { try container.encodeNil(forKey: .error) }
    }
}

public enum RuntimeEndpoint {
    public static func socketPath() -> String {
        runtimeDirectory(in: FileManager.default.temporaryDirectory)
            .appendingPathComponent("agent-v1.sock")
            .path
    }

    public static func prepare() throws -> String {
        try prepare(in: FileManager.default.temporaryDirectory)
    }

    public static func prepare(in root: URL) throws -> String {
        let directory = runtimeDirectory(in: root)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        } catch {
            throw LocalAgentTransportError.runtimeDirectoryFailed
        }

        guard chmod(directory.path, 0o700) == 0 else {
            throw LocalAgentTransportError.runtimeDirectoryFailed
        }
        var metadata = stat()
        guard stat(directory.path, &metadata) == 0 else {
            throw LocalAgentTransportError.runtimeDirectoryFailed
        }
        guard metadata.st_uid == getuid(), metadata.st_mode & 0o777 == 0o700 else {
            throw LocalAgentTransportError.insecureRuntimeDirectory
        }
        return directory.appendingPathComponent("agent-v1.sock").path
    }

    private static func runtimeDirectory(in root: URL) -> URL {
        root.appendingPathComponent("pomo", isDirectory: true)
    }
}

public final class LocalAgentServer: @unchecked Sendable {
    private let path: String
    private let agent: PomoAgentCore
    private let listener: Int32
    private let lock = NSLock()
    private var running = true

    public init(path: String, agent: PomoAgentCore) throws {
        self.path = path
        self.agent = agent
        listener = try Self.makeSocket()
        try Self.bind(listener, to: path)

        guard Darwin.listen(listener, 8) == 0 else {
            Darwin.close(listener)
            throw LocalAgentTransportError.listenFailed
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.acceptLoop()
        }
    }

    deinit {
        stop()
    }

    public func stop() {
        lock.lock()
        let wasRunning = running
        running = false
        lock.unlock()
        guard wasRunning else { return }

        Darwin.shutdown(listener, SHUT_RDWR)
        Darwin.close(listener)
        unlink(path)
    }

    private func acceptLoop() {
        while isRunning {
            let client = Darwin.accept(listener, nil, nil)
            guard client >= 0 else { continue }
            handle(client: client)
            Darwin.close(client)
        }
    }

    private func handle(client: Int32) {
        let responseWritten = DispatchSemaphore(value: 0)
        Task { [agent] in
            defer { responseWritten.signal() }
            guard let helloData = try? Self.readFrame(from: client),
                let wireMessage = try? JSONDecoder().decode(WireMessage.self, from: helloData),
                let hello = try? JSONDecoder().decode(Hello.self, from: helloData),
                wireMessage.messageType == "hello"
            else { return }

            let handshake = await agent.handshakeInfo()
            let negotiation: ProtocolNegotiation
            do {
                negotiation = try ProtocolNegotiator.negotiate(
                    agent: handshake.supportedProtocol,
                    client: hello.supportedProtocol,
                    agentCapabilities: handshake.capabilities,
                    clientCapabilities: hello.capabilities
                )
                guard
                    Self.writeJSON(
                        HelloAck(
                            messageID: UUID(),
                            replyTo: hello.messageID,
                            agentVersion: handshake.productVersion,
                            agentInstanceID: handshake.agentInstanceID,
                            negotiatedProtocol: negotiation.version,
                            capabilities: negotiation.capabilities,
                            stateRevision: handshake.revision
                        ),
                        to: client
                    )
                else { return }
            } catch {
                _ = Self.writeJSON(
                    HelloReject(
                        messageID: UUID(),
                        replyTo: hello.messageID,
                        agentVersion: handshake.productVersion,
                        supportedProtocol: handshake.supportedProtocol
                    ),
                    to: client
                )
                return
            }

            guard let requestData = try? Self.readFrame(from: client),
                let request = try? JSONDecoder().decode(IPCRequest.self, from: requestData),
                request.messageType == "request",
                request.protocolVersion == negotiation.version,
                request.agentInstanceID == handshake.agentInstanceID,
                request.command == IPCCommand(name: "status")
            else { return }
            let snapshot = await agent.snapshot()
            let response = IPCResponse(
                protocolVersion: negotiation.version,
                requestID: request.requestID,
                stateRevision: snapshot.revision,
                result: snapshot
            )
            _ = Self.writeJSON(response, to: client)
        }
        responseWritten.wait()
    }

    private var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return running
    }

    fileprivate static func makeSocket() throws -> Int32 {
        let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw LocalAgentTransportError.socketCreationFailed }
        return descriptor
    }

    private static func bind(_ descriptor: Int32, to path: String) throws {
        guard access(path, F_OK) != 0 else {
            Darwin.close(descriptor)
            throw LocalAgentTransportError.bindFailed
        }
        var address = try unixAddress(path)
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(descriptor, $0, unixAddressLength(path))
            }
        }
        guard result == 0 else {
            Darwin.close(descriptor)
            throw LocalAgentTransportError.bindFailed
        }
        guard chmod(path, 0o600) == 0 else {
            unlink(path)
            Darwin.close(descriptor)
            throw LocalAgentTransportError.bindFailed
        }
    }

    fileprivate static func readFrame(from descriptor: Int32) throws -> Data {
        let header = try readExactly(MemoryLayout<UInt32>.size, from: descriptor)
        let length = header.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self).bigEndian }
        guard length > 0, length <= FrameCodec.maximumPayloadLength else {
            throw LocalAgentTransportError.malformedRequest
        }
        let payload = try readExactly(Int(length), from: descriptor)
        return try FrameCodec.decode(header + payload)
    }

    private static func readExactly(_ count: Int, from descriptor: Int32) throws -> Data {
        var data = Data()
        while data.count < count {
            var bytes = [UInt8](repeating: 0, count: count - data.count)
            let received = Darwin.recv(descriptor, &bytes, bytes.count, 0)
            guard received > 0 else { throw LocalAgentTransportError.readFailed }
            data.append(contentsOf: bytes.prefix(Int(received)))
        }
        return data
    }

    @discardableResult
    fileprivate static func writeAll(_ data: Data, to descriptor: Int32) -> Bool {
        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return false }
            var written = 0
            while written < buffer.count {
                let result = Darwin.send(
                    descriptor, baseAddress.advanced(by: written), buffer.count - written, 0)
                guard result > 0 else { return false }
                written += Int(result)
            }
            return true
        }
    }

    private static func writeJSON<T: Encodable>(_ value: T, to descriptor: Int32) -> Bool {
        guard let payload = try? JSONEncoder().encode(value),
            let frame = try? FrameCodec.encode(payload)
        else { return false }
        return writeAll(frame, to: descriptor)
    }
}

public struct LocalAgentClient: Sendable {
    private let path: String
    private let supportedProtocol: ProtocolRange

    public init(
        path: String,
        supportedProtocol: ProtocolRange = ProtocolRange(major: 1, minimumMinor: 0, maximumMinor: 0)
    ) {
        self.path = path
        self.supportedProtocol = supportedProtocol
    }

    public func status() async throws -> PublicResponse {
        let response = try await statusResponse(requestID: UUID())
        guard let snapshot = response.result else { throw LocalAgentTransportError.invalidResponse }
        return PublicResponse.success(snapshot: snapshot)
    }

    public func statusResponse(requestID: UUID) async throws -> IPCResponse {
        let descriptor = try LocalAgentServer.makeSocket()
        defer { Darwin.close(descriptor) }
        var address = try unixAddress(path)
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(descriptor, $0, unixAddressLength(path))
            }
        }
        guard result == 0 else { throw LocalAgentTransportError.connectFailed }

        let hello = Hello(
            messageID: UUID(),
            clientName: "pomo",
            clientVersion: "0.1.0",
            supportedProtocol: supportedProtocol,
            capabilities: ["status"]
        )
        guard
            LocalAgentServer.writeAll(
                try FrameCodec.encode(try JSONEncoder().encode(hello)), to: descriptor)
        else {
            throw LocalAgentTransportError.writeFailed
        }
        let handshakeData = try LocalAgentServer.readFrame(from: descriptor)
        let handshakeType = try JSONDecoder().decode(WireMessage.self, from: handshakeData)
        guard handshakeType.messageType == "hello_ack" else {
            throw LocalAgentTransportError.protocolMismatch
        }
        let acknowledgement = try JSONDecoder().decode(HelloAck.self, from: handshakeData)

        let request = try JSONEncoder().encode(
            IPCRequest(
                protocolVersion: acknowledgement.negotiatedProtocol,
                requestID: requestID,
                agentInstanceID: acknowledgement.agentInstanceID,
                issuedAt: currentUTCTimestamp(),
                command: IPCCommand(name: "status")
            )
        )
        guard LocalAgentServer.writeAll(try FrameCodec.encode(request), to: descriptor) else {
            throw LocalAgentTransportError.writeFailed
        }
        let response = try LocalAgentServer.readFrame(from: descriptor)
        guard let decoded = try? JSONDecoder().decode(IPCResponse.self, from: response),
            decoded.messageType == "response",
            decoded.requestID == requestID,
            decoded.protocolVersion == acknowledgement.negotiatedProtocol
        else {
            throw LocalAgentTransportError.invalidResponse
        }
        return decoded
    }
}

private struct WireMessage: Decodable {
    let messageType: String

    enum CodingKeys: String, CodingKey {
        case messageType = "message_type"
    }
}

private struct Hello: Codable, Sendable {
    let messageType = "hello"
    let messageID: UUID
    let clientName: String
    let clientVersion: String
    let supportedProtocol: ProtocolRange
    let capabilities: [String]

    enum CodingKeys: String, CodingKey {
        case messageType = "message_type"
        case messageID = "message_id"
        case clientName = "client_name"
        case clientVersion = "client_version"
        case supportedProtocol = "supported_protocol"
        case capabilities
    }
}

private struct HelloAck: Codable, Sendable {
    let messageType = "hello_ack"
    let messageID: UUID
    let replyTo: UUID
    let agentVersion: String
    let agentInstanceID: UUID
    let negotiatedProtocol: ProtocolVersion
    let capabilities: [String]
    let stateRevision: UInt64

    enum CodingKeys: String, CodingKey {
        case messageType = "message_type"
        case messageID = "message_id"
        case replyTo = "reply_to"
        case agentVersion = "agent_version"
        case agentInstanceID = "agent_instance_id"
        case negotiatedProtocol = "negotiated_protocol"
        case capabilities
        case stateRevision = "state_revision"
    }
}

private struct HelloReject: Codable, Sendable {
    let messageType = "hello_reject"
    let messageID: UUID
    let replyTo: UUID
    let agentVersion: String
    let supportedProtocol: ProtocolRange

    enum CodingKeys: String, CodingKey {
        case messageType = "message_type"
        case messageID = "message_id"
        case replyTo = "reply_to"
        case agentVersion = "agent_version"
        case supportedProtocol = "supported_protocol"
    }
}

private func unixAddress(_ path: String) throws -> sockaddr_un {
    let bytes = Array(path.utf8) + [0]
    guard bytes.count <= MemoryLayout.size(ofValue: sockaddr_un().sun_path) else {
        throw LocalAgentTransportError.invalidPath
    }
    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    withUnsafeMutableBytes(of: &address.sun_path) { destination in
        bytes.withUnsafeBytes { source in destination.copyBytes(from: source) }
    }
    return address
}

private func unixAddressLength(_ path: String) -> socklen_t {
    socklen_t(MemoryLayout<sa_family_t>.size + path.utf8.count + 1)
}

private func currentUTCTimestamp() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: Date())
}

public actor PomoAgentCore {
    private let agentInstanceID: UUID
    private let productVersion: String
    private var revision: UInt64 = 0

    public init(productVersion: String) {
        self.productVersion = productVersion
        agentInstanceID = UUID()
    }

    public func snapshot() -> AgentSnapshot {
        AgentSnapshot(
            agentRunning: true,
            agentInstanceID: agentInstanceID,
            agentState: .idle,
            revision: revision
        )
    }

    fileprivate func handshakeInfo() -> AgentHandshakeInfo {
        AgentHandshakeInfo(
            productVersion: productVersion,
            agentInstanceID: agentInstanceID,
            revision: revision,
            supportedProtocol: ProtocolRange(major: 1, minimumMinor: 0, maximumMinor: 0),
            capabilities: ["status"]
        )
    }
}

private struct AgentHandshakeInfo: Sendable {
    let productVersion: String
    let agentInstanceID: UUID
    let revision: UInt64
    let supportedProtocol: ProtocolRange
    let capabilities: [String]
}
