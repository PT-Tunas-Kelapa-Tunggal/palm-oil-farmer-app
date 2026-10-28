import Foundation
import Observation
import CryptoKit

@MainActor
@Observable
final class ReviewReportDownload {
    static let shared = ReviewReportDownload()
    private(set) var activeURL: URL?
    private(set) var receivedBytes: Int64 = 0
    private(set) var expectedBytes: Int64 = 0
    private(set) var errorMessage: String?
    private(set) var savedFiles: [URL: URL] = [:]
    private var task: Task<Void, Never>?

    var progress: Double? {
        guard expectedBytes > 0 else { return nil }
        return min(1, Double(receivedBytes) / Double(expectedBytes))
    }

    func savedFile(for source: URL) -> URL? {
        if source.isFileURL { return source }
        let destination = destination(for: source)
        return FileManager.default.fileExists(atPath: destination.path) ? destination : nil
    }

    func start(_ source: URL) {
        guard activeURL == nil, savedFile(for: source) == nil else { return }
        activeURL = source
        receivedBytes = 0
        expectedBytes = 0
        errorMessage = nil
        // The task belongs to the download store so leaving the status screen doesn't cancel it.
        task = Task {
            defer { activeURL = nil; task = nil }
            do {
                let (bytes, response) = try await URLSession.shared.bytes(from: source)
                if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                    throw URLError(.badServerResponse)
                }
                expectedBytes = response.expectedContentLength
                let temporary = URL.temporaryDirectory.appending(path: UUID().uuidString)
                guard FileManager.default.createFile(atPath: temporary.path, contents: nil) else {
                    throw CocoaError(.fileWriteUnknown)
                }
                let handle = try FileHandle(forWritingTo: temporary)
                defer {
                    try? handle.close()
                    try? FileManager.default.removeItem(at: temporary)
                }
                var buffer = Data()
                var count: Int64 = 0
                for try await byte in bytes {
                    try Task.checkCancellation()
                    buffer.append(byte)
                    count += 1
                    if buffer.count == 65_536 {
                        try handle.write(contentsOf: buffer)
                        buffer.removeAll(keepingCapacity: true)
                        receivedBytes = count
                    }
                }
                if !buffer.isEmpty { try handle.write(contentsOf: buffer) }
                try handle.close()
                receivedBytes = count
                let destination = destination(for: source)
                try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: temporary, to: destination)
                savedFiles[source] = destination
            } catch {
                errorMessage = "Hasil belum diunduh. Periksa koneksi internet dan coba lagi."
            }
        }
    }

    private func destination(for source: URL) -> URL {
        let key = SHA256.hash(data: Data(source.absoluteString.utf8))
            .map { String(format: "%02x", $0) }.joined()
        let fileExtension = source.pathExtension.isEmpty ? "pdf" : source.pathExtension
        return URL.applicationSupportDirectory.appending(path: "ReviewReports")
            .appending(path: key + "." + fileExtension)
    }
}
