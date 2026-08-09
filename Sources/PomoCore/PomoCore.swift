import Darwin
import Foundation

public enum AgentState: String, Codable, Sendable {
    case notRunning = "not_running"
    case idle
    case session
    case recovery
}

public enum SessionState: String, Codable, Sendable {
    case ready
    case running
    case paused
    case blocked
}

public enum PhaseType: String, Codable, Sendable {
    case focus
    case shortBreak = "short_break"
    case longBreak = "long_break"
}

public struct SessionConfiguration: Codable, Equatable, Sendable {
    public let focusSeconds: Int
    public let shortBreakSeconds: Int
    public let longBreakSeconds: Int
    public let longBreakEvery: Int
    public let openEnded: Bool
    public let targetRounds: Int?
    public let autoStartFocus: Bool
    public let autoStartBreaks: Bool

    public static let classic = SessionConfiguration(
        focusSeconds: 1_500, shortBreakSeconds: 300, longBreakSeconds: 900,
        longBreakEvery: 4, openEnded: false, targetRounds: 4,
        autoStartFocus: false, autoStartBreaks: true
    )
}

public struct AgentSnapshot: Codable, Equatable, Sendable {
    public let agentRunning: Bool
    public let agentInstanceID: UUID?
    public let agentState: AgentState
    public let revision: UInt64
    public let session: SessionSnapshot?
    public let recovery: RecoverySnapshot?
    public let sessionID: UUID?
    public let sessionState: SessionState?
    public let phaseID: UUID?
    public let phaseType: PhaseType?
    public let configuration: SessionConfiguration?
    public let completedRounds: Int?
    public let configuredDurationSeconds: Int?
    public let remainingSeconds: Int?
    public let phaseStartedAt: String?
    public let expectedTransitionAt: String?

    public init(
        agentRunning: Bool,
        agentInstanceID: UUID?,
        agentState: AgentState,
        revision: UInt64,
        session: SessionSnapshot? = nil,
        recovery: RecoverySnapshot? = nil,
        sessionID: UUID? = nil,
        sessionState: SessionState? = nil,
        phaseID: UUID? = nil,
        phaseType: PhaseType? = nil,
        configuration: SessionConfiguration? = nil,
        completedRounds: Int? = nil,
        configuredDurationSeconds: Int? = nil,
        remainingSeconds: Int? = nil,
        phaseStartedAt: String? = nil,
        expectedTransitionAt: String? = nil
    ) {
        self.agentRunning = agentRunning
        self.agentInstanceID = agentInstanceID
        self.agentState = agentState
        self.revision = revision
        self.session = session
        self.recovery = recovery
        self.sessionID = sessionID
        self.sessionState = sessionState
        self.phaseID = phaseID
        self.phaseType = phaseType
        self.configuration = configuration
        self.completedRounds = completedRounds
        self.configuredDurationSeconds = configuredDurationSeconds
        self.remainingSeconds = remainingSeconds
        self.phaseStartedAt = phaseStartedAt
        self.expectedTransitionAt = expectedTransitionAt
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
        if let agentInstanceID {
            try container.encode(agentInstanceID.uuidString.lowercased(), forKey: .agentInstanceID)
        } else {
            try container.encodeNil(forKey: .agentInstanceID)
        }
        try container.encode(agentState, forKey: .agentState)
        try container.encode(revision, forKey: .revision)
        try container.encodeIfPresent(sessionID, forKey: .sessionID)
        if sessionID == nil { try container.encodeNil(forKey: .sessionID) }
        try container.encodeIfPresent(sessionState, forKey: .sessionState)
        if sessionState == nil { try container.encodeNil(forKey: .sessionState) }
        try container.encodeIfPresent(phaseID, forKey: .phaseID)
        if phaseID == nil { try container.encodeNil(forKey: .phaseID) }
        try container.encodeIfPresent(phaseType, forKey: .phaseType)
        if phaseType == nil { try container.encodeNil(forKey: .phaseType) }
        try container.encodeNil(forKey: .sourcePresetName)
        try container.encodeIfPresent(configuration, forKey: .configuration)
        if configuration == nil { try container.encodeNil(forKey: .configuration) }
        try container.encodeIfPresent(completedRounds, forKey: .completedRounds)
        if completedRounds == nil { try container.encodeNil(forKey: .completedRounds) }
        try container.encodeIfPresent(configuredDurationSeconds, forKey: .configuredDurationSeconds)
        if configuredDurationSeconds == nil {
            try container.encodeNil(forKey: .configuredDurationSeconds)
        }
        try container.encodeIfPresent(remainingSeconds, forKey: .remainingSeconds)
        if remainingSeconds == nil { try container.encodeNil(forKey: .remainingSeconds) }
        try container.encodeNil(forKey: .sessionStartedAt)
        try container.encodeIfPresent(phaseStartedAt, forKey: .phaseStartedAt)
        if phaseStartedAt == nil { try container.encodeNil(forKey: .phaseStartedAt) }
        try container.encodeIfPresent(expectedTransitionAt, forKey: .expectedTransitionAt)
        if expectedTransitionAt == nil { try container.encodeNil(forKey: .expectedTransitionAt) }
        try container.encodeNil(forKey: .recovery)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            agentRunning: try container.decode(Bool.self, forKey: .agentRunning),
            agentInstanceID: try container.decodeIfPresent(UUID.self, forKey: .agentInstanceID),
            agentState: try container.decode(AgentState.self, forKey: .agentState),
            revision: try container.decode(UInt64.self, forKey: .revision),
            sessionID: try container.decodeIfPresent(UUID.self, forKey: .sessionID),
            sessionState: try container.decodeIfPresent(SessionState.self, forKey: .sessionState),
            phaseID: try container.decodeIfPresent(UUID.self, forKey: .phaseID),
            phaseType: try container.decodeIfPresent(PhaseType.self, forKey: .phaseType),
            configuration: try container.decodeIfPresent(
                SessionConfiguration.self, forKey: .configuration),
            completedRounds: try container.decodeIfPresent(Int.self, forKey: .completedRounds),
            configuredDurationSeconds: try container.decodeIfPresent(
                Int.self, forKey: .configuredDurationSeconds),
            remainingSeconds: try container.decodeIfPresent(Int.self, forKey: .remainingSeconds),
            phaseStartedAt: try container.decodeIfPresent(String.self, forKey: .phaseStartedAt),
            expectedTransitionAt: try container.decodeIfPresent(
                String.self, forKey: .expectedTransitionAt)
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
    public let command: String
    public let ok: Bool
    public let data: AgentSnapshot?
    public let error: PublicError?

    public static func success(snapshot: AgentSnapshot) -> PublicResponse {
        success(command: "status", snapshot: snapshot)
    }

    public static func success(command: String, snapshot: AgentSnapshot) -> PublicResponse {
        PublicResponse(
            schemaVersion: 1, command: command, ok: true, data: snapshot, error: nil)
    }

    public static func agentNotRunning() -> PublicResponse {
        PublicResponse(
            schemaVersion: 1,
            command: "status",
            ok: true,
            data: AgentSnapshot(
                agentRunning: false,
                agentInstanceID: nil,
                agentState: .notRunning,
                revision: 0
            ),
            error: nil
        )
    }

    public static func failure(_ error: PublicError, command: String = "status") -> PublicResponse {
        PublicResponse(
            schemaVersion: 1, command: command, ok: false, data: nil, error: error)
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case command
        case ok
        case data
        case error
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(command, forKey: .command)
        try container.encode(ok, forKey: .ok)
        try container.encodeIfPresent(data, forKey: .data)
        if data == nil { try container.encodeNil(forKey: .data) }
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
    case lockFailed
    case insecureEndpoint
}

public struct IPCCommand: Codable, Equatable, Sendable {
    public let name: String
    public let arguments: MutationArguments

    public init(name: String, replace: Bool = false) {
        self.name = name
        arguments = MutationArguments(replace: replace)
    }
}

public struct MutationArguments: Codable, Equatable, Sendable {
    public let replace: Bool

    public init(replace: Bool = false) {
        self.replace = replace
    }
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

    public init(
        protocolVersion: ProtocolVersion,
        requestID: UUID,
        stateRevision: UInt64,
        error: PublicError
    ) {
        messageType = "response"
        self.protocolVersion = protocolVersion
        self.requestID = requestID
        ok = false
        self.stateRevision = stateRevision
        result = nil
        self.error = error
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
    private let ownershipLock: Int32
    private let lock = NSLock()
    private var running = true

    public init(path: String, agent: PomoAgentCore) throws {
        self.path = path
        self.agent = agent
        listener = try Self.makeSocket()
        ownershipLock = try Self.acquireLock(for: path)
        do {
            try Self.prepareEndpoint(at: path)
            try Self.bind(listener, to: path)
        } catch {
            Darwin.close(ownershipLock)
            Darwin.close(listener)
            throw error
        }

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
        Darwin.close(ownershipLock)
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
                request.protocolVersion == negotiation.version
            else { return }
            let response: IPCResponse
            do {
                let snapshot: AgentSnapshot
                switch request.command.name {
                case "status":
                    guard request.command == IPCCommand(name: "status") else { return }
                    snapshot = await agent.snapshot()
                case "start":
                    snapshot = try await agent.startClassic(
                        requestID: request.requestID,
                        issuedAt: request.issuedAt,
                        agentInstanceID: request.agentInstanceID,
                        replace: request.command.arguments.replace
                    )
                case "stop":
                    guard request.command == IPCCommand(name: "stop") else { return }
                    snapshot = try await agent.stopSession(
                        requestID: request.requestID,
                        issuedAt: request.issuedAt,
                        agentInstanceID: request.agentInstanceID
                    )
                case "pause":
                    guard request.command == IPCCommand(name: "pause") else { return }
                    snapshot = try await agent.pauseSession(
                        requestID: request.requestID,
                        issuedAt: request.issuedAt,
                        agentInstanceID: request.agentInstanceID
                    )
                case "resume":
                    guard request.command == IPCCommand(name: "resume") else { return }
                    snapshot = try await agent.resumeSession(
                        requestID: request.requestID,
                        issuedAt: request.issuedAt,
                        agentInstanceID: request.agentInstanceID
                    )
                case "skip":
                    guard request.command == IPCCommand(name: "skip") else { return }
                    snapshot = try await agent.skipPhase(
                        requestID: request.requestID,
                        issuedAt: request.issuedAt,
                        agentInstanceID: request.agentInstanceID
                    )
                default:
                    return
                }
                response = IPCResponse(
                    protocolVersion: negotiation.version,
                    requestID: request.requestID,
                    stateRevision: snapshot.revision,
                    result: snapshot
                )
            } catch let error as AgentCommandError {
                let snapshot = await agent.snapshot()
                response = IPCResponse(
                    protocolVersion: negotiation.version,
                    requestID: request.requestID,
                    stateRevision: snapshot.revision,
                    error: error.publicError(currentState: snapshot.agentState)
                )
            } catch {
                return
            }
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

    private static func acquireLock(for socketPath: String) throws -> Int32 {
        let lockPath = (socketPath as NSString).deletingPathExtension + ".lock"
        let descriptor = Darwin.open(lockPath, O_CREAT | O_RDWR, 0o600)
        guard descriptor >= 0 else { throw LocalAgentTransportError.lockFailed }
        guard chmod(lockPath, 0o600) == 0, flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            Darwin.close(descriptor)
            throw LocalAgentTransportError.lockFailed
        }
        return descriptor
    }

    private static func prepareEndpoint(at path: String) throws {
        guard access(path, F_OK) == 0 else { return }
        var metadata = stat()
        guard stat(path, &metadata) == 0,
            metadata.st_uid == getuid(),
            metadata.st_mode & S_IFMT == S_IFSOCK
        else { throw LocalAgentTransportError.insecureEndpoint }

        if endpointIsReachable(path) {
            throw LocalAgentTransportError.bindFailed
        }
        guard unlink(path) == 0 else { throw LocalAgentTransportError.bindFailed }
    }

    private static func endpointIsReachable(_ path: String) -> Bool {
        guard let descriptor = try? makeSocket() else { return true }
        defer { Darwin.close(descriptor) }
        guard var address = try? unixAddress(path) else { return true }
        return withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(descriptor, $0, unixAddressLength(path)) == 0
            }
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

    public func startClassic(replace: Bool = false) async throws -> PublicResponse {
        let response = try await startClassicResponse(requestID: UUID(), replace: replace)
        guard response.ok, let snapshot = response.result else {
            return .failure(
                response.error
                    ?? PublicError(
                        code: "invalid_response", message: "Invalid Agent response.", exitCode: 1),
                command: "start"
            )
        }
        return PublicResponse.success(command: "start", snapshot: snapshot)
    }

    public func stop() async throws -> PublicResponse {
        let response = try await stopResponse(requestID: UUID())
        guard response.ok, let snapshot = response.result else {
            return .failure(
                response.error
                    ?? PublicError(
                        code: "invalid_response", message: "Invalid Agent response.", exitCode: 1),
                command: "stop"
            )
        }
        return PublicResponse.success(command: "stop", snapshot: snapshot)
    }

    public func pause() async throws -> PublicResponse {
        try await mutationResponse(command: "pause")
    }

    public func resume() async throws -> PublicResponse {
        try await mutationResponse(command: "resume")
    }

    public func skip() async throws -> PublicResponse {
        try await mutationResponse(command: "skip")
    }

    public func statusResponse(requestID: UUID) async throws -> IPCResponse {
        try await commandResponse(command: "status", requestID: requestID)
    }

    public func startClassicResponse(
        requestID: UUID,
        replace: Bool = false,
        issuedAt: String? = nil,
        agentInstanceID: UUID? = nil
    ) async throws -> IPCResponse {
        try await commandResponse(
            command: "start", requestID: requestID, replace: replace, issuedAt: issuedAt,
            agentInstanceID: agentInstanceID)
    }

    public func stopResponse(
        requestID: UUID,
        issuedAt: String? = nil,
        agentInstanceID: UUID? = nil
    ) async throws -> IPCResponse {
        try await commandResponse(
            command: "stop", requestID: requestID, issuedAt: issuedAt,
            agentInstanceID: agentInstanceID)
    }

    public func pauseResponse(
        requestID: UUID,
        issuedAt: String? = nil,
        agentInstanceID: UUID? = nil
    ) async throws -> IPCResponse {
        try await commandResponse(
            command: "pause", requestID: requestID, issuedAt: issuedAt,
            agentInstanceID: agentInstanceID)
    }

    public func resumeResponse(
        requestID: UUID,
        issuedAt: String? = nil,
        agentInstanceID: UUID? = nil
    ) async throws -> IPCResponse {
        try await commandResponse(
            command: "resume", requestID: requestID, issuedAt: issuedAt,
            agentInstanceID: agentInstanceID)
    }

    public func skipResponse(
        requestID: UUID,
        issuedAt: String? = nil,
        agentInstanceID: UUID? = nil
    ) async throws -> IPCResponse {
        try await commandResponse(
            command: "skip", requestID: requestID, issuedAt: issuedAt,
            agentInstanceID: agentInstanceID)
    }

    private func mutationResponse(command: String) async throws -> PublicResponse {
        let response = try await commandResponse(command: command, requestID: UUID())
        guard response.ok, let snapshot = response.result else {
            return .failure(
                response.error
                    ?? PublicError(
                        code: "invalid_response", message: "Invalid Agent response.", exitCode: 1),
                command: command
            )
        }
        return PublicResponse.success(command: command, snapshot: snapshot)
    }

    private func commandResponse(
        command: String,
        requestID: UUID,
        replace: Bool = false,
        issuedAt: String? = nil,
        agentInstanceID: UUID? = nil
    ) async throws -> IPCResponse {
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
                agentInstanceID: agentInstanceID ?? acknowledgement.agentInstanceID,
                issuedAt: issuedAt ?? currentUTCTimestamp(),
                command: IPCCommand(name: command, replace: replace)
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
    private static let mutationRetryWindow: TimeInterval = 300
    private static let maximumFutureRequestSkew: TimeInterval = 30
    private let agentInstanceID: UUID
    private let productVersion: String
    private var revision: UInt64 = 0
    private var activeSession: ActiveSession?
    private var completedMutations: [UUID: CachedMutation] = [:]

    public init(productVersion: String) {
        self.productVersion = productVersion
        agentInstanceID = UUID()
    }

    public func snapshot() -> AgentSnapshot {
        if let activeSession {
            let duration = activeSession.duration
            let remaining = activeSession.remaining(at: Date())
            return AgentSnapshot(
                agentRunning: true, agentInstanceID: agentInstanceID, agentState: .session,
                revision: revision, sessionID: activeSession.id, sessionState: activeSession.state,
                phaseID: activeSession.phaseID, phaseType: activeSession.phaseType,
                configuration: activeSession.configuration, completedRounds: 0,
                configuredDurationSeconds: duration, remainingSeconds: remaining,
                phaseStartedAt: activeSession.startedAt.map(timestamp),
                expectedTransitionAt: activeSession.startedAt.map {
                    timestamp($0.addingTimeInterval(Double(activeSession.remainingSeconds)))
                }
            )
        }
        return AgentSnapshot(
            agentRunning: true,
            agentInstanceID: agentInstanceID,
            agentState: .idle,
            revision: revision
        )
    }

    public func startClassic() throws -> AgentSnapshot {
        try startClassic(
            requestID: UUID(), issuedAt: currentUTCTimestamp(), agentInstanceID: agentInstanceID,
            replace: false)
    }

    fileprivate func startClassic(
        requestID: UUID,
        issuedAt: String,
        agentInstanceID: UUID,
        replace: Bool
    ) throws -> AgentSnapshot {
        if let cached = try cachedMutation(
            requestID: requestID, issuedAt: issuedAt, agentInstanceID: agentInstanceID)
        {
            return cached
        }
        guard activeSession == nil || replace else { throw AgentCommandError.sessionAlreadyActive }
        activeSession = ActiveSession(
            id: UUID(), phaseID: UUID(), configuration: .classic, phaseType: .focus,
            state: .running, remainingSeconds: SessionConfiguration.classic.focusSeconds,
            startedAt: Date())
        revision += 1
        let result = snapshot()
        completedMutations[requestID] = CachedMutation(snapshot: result, completedAt: Date())
        return result
    }

    public func pauseSession() throws -> AgentSnapshot {
        try pauseSession(
            requestID: UUID(), issuedAt: currentUTCTimestamp(), agentInstanceID: agentInstanceID)
    }

    fileprivate func pauseSession(
        requestID: UUID,
        issuedAt: String,
        agentInstanceID: UUID
    ) throws -> AgentSnapshot {
        if let cached = try cachedMutation(
            requestID: requestID, issuedAt: issuedAt, agentInstanceID: agentInstanceID)
        {
            return cached
        }
        guard let activeSession else { throw AgentCommandError.noActiveSession }
        guard activeSession.phaseType == .focus, activeSession.state == .running else {
            throw AgentCommandError.invalidTransition
        }
        let remaining = activeSession.remaining(at: Date())
        guard remaining > 0 else { throw AgentCommandError.invalidTransition }
        self.activeSession = activeSession.paused(remainingSeconds: remaining)
        revision += 1
        let result = snapshot()
        completedMutations[requestID] = CachedMutation(snapshot: result, completedAt: Date())
        return result
    }

    public func resumeSession() throws -> AgentSnapshot {
        try resumeSession(
            requestID: UUID(), issuedAt: currentUTCTimestamp(), agentInstanceID: agentInstanceID)
    }

    fileprivate func resumeSession(
        requestID: UUID,
        issuedAt: String,
        agentInstanceID: UUID
    ) throws -> AgentSnapshot {
        if let cached = try cachedMutation(
            requestID: requestID, issuedAt: issuedAt, agentInstanceID: agentInstanceID)
        {
            return cached
        }
        guard let activeSession else { throw AgentCommandError.noActiveSession }
        guard activeSession.phaseType == .focus, activeSession.state == .paused else {
            throw AgentCommandError.invalidTransition
        }
        self.activeSession = activeSession.running(from: Date())
        revision += 1
        let result = snapshot()
        completedMutations[requestID] = CachedMutation(snapshot: result, completedAt: Date())
        return result
    }

    public func skipPhase() throws -> AgentSnapshot {
        try skipPhase(
            requestID: UUID(), issuedAt: currentUTCTimestamp(), agentInstanceID: agentInstanceID)
    }

    fileprivate func skipPhase(
        requestID: UUID,
        issuedAt: String,
        agentInstanceID: UUID
    ) throws -> AgentSnapshot {
        if let cached = try cachedMutation(
            requestID: requestID, issuedAt: issuedAt, agentInstanceID: agentInstanceID)
        {
            return cached
        }
        guard let activeSession else { throw AgentCommandError.noActiveSession }
        guard activeSession.phaseType == .focus,
            activeSession.state == .running || activeSession.state == .paused
        else { throw AgentCommandError.invalidTransition }
        self.activeSession = ActiveSession(
            id: activeSession.id, phaseID: UUID(), configuration: activeSession.configuration,
            phaseType: .shortBreak, state: .running,
            remainingSeconds: activeSession.configuration.shortBreakSeconds, startedAt: Date())
        revision += 1
        let result = snapshot()
        completedMutations[requestID] = CachedMutation(snapshot: result, completedAt: Date())
        return result
    }

    public func stopSession() throws -> AgentSnapshot {
        try stopSession(
            requestID: UUID(), issuedAt: currentUTCTimestamp(), agentInstanceID: agentInstanceID)
    }

    fileprivate func stopSession(
        requestID: UUID,
        issuedAt: String,
        agentInstanceID: UUID
    ) throws -> AgentSnapshot {
        if let cached = try cachedMutation(
            requestID: requestID, issuedAt: issuedAt, agentInstanceID: agentInstanceID)
        {
            return cached
        }
        guard activeSession != nil else { throw AgentCommandError.noActiveSession }
        activeSession = nil
        revision += 1
        let result = snapshot()
        completedMutations[requestID] = CachedMutation(snapshot: result, completedAt: Date())
        return result
    }

    private func cachedMutation(
        requestID: UUID,
        issuedAt: String,
        agentInstanceID: UUID
    ) throws -> AgentSnapshot? {
        guard agentInstanceID == self.agentInstanceID else {
            throw AgentCommandError.wrongAgent
        }
        guard let requestDate = parseUTCTimestamp(issuedAt) else {
            throw AgentCommandError.invalidRequestTimestamp
        }
        let now = Date()
        guard requestDate <= now.addingTimeInterval(Self.maximumFutureRequestSkew) else {
            throw AgentCommandError.requestFromFuture
        }
        guard now.timeIntervalSince(requestDate) <= Self.mutationRetryWindow else {
            throw AgentCommandError.requestExpired
        }
        completedMutations = completedMutations.filter {
            now.timeIntervalSince($0.value.completedAt) <= Self.mutationRetryWindow
        }
        return completedMutations[requestID]?.snapshot
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

public enum AgentCommandError: Error, Equatable, Sendable {
    case sessionAlreadyActive
    case noActiveSession
    case requestExpired
    case requestFromFuture
    case wrongAgent
    case invalidRequestTimestamp
    case invalidTransition

    fileprivate func publicError(currentState: AgentState) -> PublicError {
        switch self {
        case .sessionAlreadyActive:
            return PublicError(
                code: "invalid_state",
                message:
                    "A Session is already active. Current state: \(currentState.rawValue). Valid next actions: stop.",
                exitCode: 3)
        case .noActiveSession:
            return PublicError(
                code: "invalid_state",
                message:
                    "No Session is active. Current state: \(currentState.rawValue). Valid next actions: start.",
                exitCode: 3)
        case .invalidTransition:
            return PublicError(
                code: "invalid_state",
                message: "The current Phase does not accept that action.",
                exitCode: 3)
        case .requestExpired:
            return PublicError(
                code: "invalid_request", message: "Mutating request is older than five minutes.",
                exitCode: 3)
        case .requestFromFuture:
            return PublicError(
                code: "invalid_request",
                message: "Mutating request is more than thirty seconds in the future.",
                exitCode: 3)
        case .wrongAgent:
            return PublicError(
                code: "invalid_request",
                message: "Mutating request targets a different Agent instance.",
                exitCode: 3)
        case .invalidRequestTimestamp:
            return PublicError(
                code: "invalid_request", message: "Mutating request has an invalid UTC timestamp.",
                exitCode: 3)
        }
    }
}

private struct ActiveSession: Sendable {
    let id: UUID
    let phaseID: UUID
    let configuration: SessionConfiguration
    let phaseType: PhaseType
    let state: SessionState
    let remainingSeconds: Int
    let startedAt: Date?

    var duration: Int {
        switch phaseType {
        case .focus: configuration.focusSeconds
        case .shortBreak: configuration.shortBreakSeconds
        case .longBreak: configuration.longBreakSeconds
        }
    }

    func remaining(at date: Date) -> Int {
        guard let startedAt else { return remainingSeconds }
        return max(0, Int(ceil(Double(remainingSeconds) - date.timeIntervalSince(startedAt))))
    }

    func paused(remainingSeconds: Int) -> ActiveSession {
        ActiveSession(
            id: id, phaseID: phaseID, configuration: configuration, phaseType: phaseType,
            state: .paused, remainingSeconds: remainingSeconds, startedAt: nil)
    }

    func running(from date: Date) -> ActiveSession {
        ActiveSession(
            id: id, phaseID: phaseID, configuration: configuration, phaseType: phaseType,
            state: .running, remainingSeconds: remainingSeconds, startedAt: date)
    }
}

private struct CachedMutation: Sendable {
    let snapshot: AgentSnapshot
    let completedAt: Date
}

private func timestamp(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}

private func parseUTCTimestamp(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: value)
}

private struct AgentHandshakeInfo: Sendable {
    let productVersion: String
    let agentInstanceID: UUID
    let revision: UInt64
    let supportedProtocol: ProtocolRange
    let capabilities: [String]
}
