import Foundation
import Darwin

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
		case revision
		case session
		case recovery
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(agentRunning, forKey: .agentRunning)
		try container.encode(agentInstanceID, forKey: .agentInstanceID)
		try container.encode(agentState, forKey: .agentState)
		try container.encode(revision, forKey: .revision)
		try container.encodeIfPresent(session, forKey: .session)
		if session == nil { try container.encodeNil(forKey: .session) }
		try container.encodeIfPresent(recovery, forKey: .recovery)
		if recovery == nil { try container.encodeNil(forKey: .recovery) }
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
		PublicResponse(schemaVersion: 1, success: true, agentRunning: true, snapshot: snapshot, error: nil)
	}

	public static func agentNotRunning() -> PublicResponse {
		PublicResponse(schemaVersion: 1, success: true, agentRunning: false, snapshot: nil, error: nil)
	}

	public static func failure(_ error: PublicError) -> PublicResponse {
		PublicResponse(schemaVersion: 1, success: false, agentRunning: false, snapshot: nil, error: error)
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
}

public enum RuntimeEndpoint {
	public static func socketPath() -> String {
		FileManager.default.temporaryDirectory
			.appendingPathComponent("pomo-agent-v1.sock")
			.path
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
		guard let requestData = try? Self.readFrame(from: client),
			  let request = try? JSONDecoder().decode(StatusRequest.self, from: requestData),
			  request.command == "status"
		else {
			return
		}

		let responseWritten = DispatchSemaphore(value: 0)
		Task { [agent] in
			defer { responseWritten.signal() }
			let response = PublicResponse.success(snapshot: await agent.snapshot())
			guard let payload = try? JSONEncoder().encode(response),
				  let frame = try? FrameCodec.encode(payload)
			else { return }
			_ = Self.writeAll(frame, to: client)
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
				let result = Darwin.send(descriptor, baseAddress.advanced(by: written), buffer.count - written, 0)
				guard result > 0 else { return false }
				written += Int(result)
			}
			return true
		}
	}
}

public struct LocalAgentClient: Sendable {
	private let path: String

	public init(path: String) {
		self.path = path
	}

	public func status() async throws -> PublicResponse {
		let descriptor = try LocalAgentServer.makeSocket()
		defer { Darwin.close(descriptor) }
		var address = try unixAddress(path)
		let result = withUnsafePointer(to: &address) { pointer in
			pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
				Darwin.connect(descriptor, $0, unixAddressLength(path))
			}
		}
		guard result == 0 else { throw LocalAgentTransportError.connectFailed }

		let request = try JSONEncoder().encode(StatusRequest(command: "status"))
		guard LocalAgentServer.writeAll(try FrameCodec.encode(request), to: descriptor) else {
			throw LocalAgentTransportError.writeFailed
		}
		let response = try LocalAgentServer.readFrame(from: descriptor)
		guard let decoded = try? JSONDecoder().decode(PublicResponse.self, from: response) else {
			throw LocalAgentTransportError.invalidResponse
		}
		return decoded
	}
}

private struct StatusRequest: Codable, Sendable {
	let command: String
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
}