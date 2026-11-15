import Foundation

final class MediaRemoteClient: @unchecked Sendable {
    private let binary: URL
    private let queue = DispatchQueue(label: "notchlocal.mediaremote")
    private var streamProcess: Process?
    private var streamHandle: FileHandle?
    private var streamBuffer = Data()

    static func make() -> MediaRemoteClient? {
        let paths = [
            "/opt/homebrew/bin/media-control",
            "/usr/local/bin/media-control"
        ]
        guard let path = paths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            return nil
        }
        return MediaRemoteClient(binary: URL(fileURLWithPath: path))
    }

    private init(binary: URL) {
        self.binary = binary
    }

    func getMetadata() async -> MediaRemoteInfo? {
        await run(arguments: ["get", "--no-artwork", "--now", "--allow-missing-title"])
    }

    func getArtwork() async -> Data? {
        await run(arguments: ["get", "--allow-missing-title"])?.artworkData
    }

    func send(_ arguments: [String]) async {
        _ = await run(arguments: arguments)
    }

    func startStream(onUpdate: @escaping @Sendable (MediaRemoteInfo?) -> Void) {
        queue.async {
            self.stopStreamLocked()
            let process = Process()
            process.executableURL = self.binary
            process.arguments = ["stream", "--no-diff", "--no-artwork", "--allow-missing-title", "--debounce=250"]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            self.streamBuffer = Data()
            let handle = pipe.fileHandleForReading
            let queue = self.queue
            handle.readabilityHandler = { file in
                let data = file.availableData
                queue.async {
                    self.consumeStream(data, onUpdate: onUpdate)
                }
            }
            do {
                try process.run()
                self.streamProcess = process
                self.streamHandle = handle
            } catch {
                handle.readabilityHandler = nil
            }
        }
    }

    func stopStream() {
        queue.sync {
            stopStreamLocked()
        }
    }

    private func stopStreamLocked() {
        streamHandle?.readabilityHandler = nil
        streamHandle = nil
        if let process = streamProcess, process.isRunning {
            process.terminate()
        }
        streamProcess = nil
        streamBuffer = Data()
    }

    private func consumeStream(_ chunk: Data, onUpdate: @escaping @Sendable (MediaRemoteInfo?) -> Void) {
        guard !chunk.isEmpty else { return }
        streamBuffer.append(chunk)
        while let newline = streamBuffer.firstIndex(of: 0x0A) {
            let line = Data(streamBuffer[..<newline])
            streamBuffer.removeSubrange(...newline)
            guard !line.isEmpty else { continue }
            onUpdate(Self.parse(line))
        }
    }

    private func run(arguments: [String]) async -> MediaRemoteInfo? {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.runProcess(arguments: arguments))
            }
        }
    }

    private func runProcess(arguments: [String]) -> MediaRemoteInfo? {
        let process = Process()
        process.executableURL = binary
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return Self.parse(data)
    }

    static func parse(_ data: Data) -> MediaRemoteInfo? {
        guard !data.isEmpty,
              let object = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        let payload: [String: Any]
        if let root = object as? [String: Any], let nested = root["payload"] as? [String: Any] {
            payload = nested
        } else if let root = object as? [String: Any] {
            payload = root
        } else {
            return nil
        }

        let bundle = payload["bundleIdentifier"] as? String
            ?? payload["parentApplicationBundleIdentifier"] as? String
        guard let bundle, !bundle.isEmpty else { return nil }

        let title = (payload["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let artist = payload["artist"] as? String ?? ""
        let album = payload["album"] as? String ?? ""
        let resolvedTitle = !title.isEmpty ? title : (!album.isEmpty ? album : "Now Playing")

        return MediaRemoteInfo(
            bundleIdentifier: bundle,
            parentBundleIdentifier: payload["parentApplicationBundleIdentifier"] as? String,
            title: resolvedTitle,
            artist: artist,
            isPlaying: bool(payload["playing"]) ?? false,
            elapsedTime: number(payload["elapsedTimeNow"]) ?? number(payload["elapsedTime"]) ?? 0,
            duration: number(payload["duration"]) ?? 0,
            capturedAt: date(payload["timestamp"]) ?? Date(),
            artworkData: dataValue(payload["artworkData"])
        )
    }

    private static func number(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }

    private static func bool(_ value: Any?) -> Bool? {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return nil
    }

    private static func date(_ value: Any?) -> Date? {
        guard let value = value as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }

    private static func dataValue(_ value: Any?) -> Data? {
        guard let value = value as? String else { return nil }
        return Data(base64Encoded: value)
    }
}
