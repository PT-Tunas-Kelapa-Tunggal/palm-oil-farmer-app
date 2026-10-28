import Foundation
import CryptoKit

@MainActor
final class CloudKitWebFarmerReviewRepository: FarmerReviewRepository {
    typealias Transport = (URLRequest) async throws -> (Data, HTTPURLResponse)
    typealias Authenticate = (URL) async throws -> String

    private let configuration: CloudKitWebConfiguration
    private let transport: Transport
    private let authenticate: Authenticate
    private let mapper = PlantationDomainMapper()
    private var webAuthToken: String?
    private var requestInFlight = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(configuration: CloudKitWebConfiguration,
         transport: @escaping Transport = { request in
             let (data, response) = try await URLSession.shared.data(for: request)
             guard let http = response as? HTTPURLResponse else { throw CloudKitWebError.invalidResponse }
             return (data, http)
         },
         authenticate: @escaping Authenticate = { try await CloudKitWebSignIn.authenticate(at: $0) }) {
        self.configuration = configuration
        self.transport = transport
        self.authenticate = authenticate
    }

    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        let record = try CloudKitWebRecordAdapter.encode(mapper.toDTO(from: request))
        let response = try await send("records/modify", body: [
            "operations": [["operationType": "create", "record": record]]
        ], allowsSignIn: true)
        guard let saved = try records(in: response).first else { throw CloudKitWebError.invalidResponse }
        return try await domain(from: saved)
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        try await fetchRequest(for: gardenID, allowsSignIn: false)
    }

    func fetchRequest(for gardenID: UUID, allowsSignIn: Bool) async throws -> PlantationReviewRequest? {
        let response = try await send("records/query", body: [
            "query": [
                "recordType": PlantationRecordCKAdapter.recordType,
                "filterBy": [["fieldName": "gardenID", "comparator": "EQUALS",
                              "fieldValue": ["value": gardenID.uuidString, "type": "STRING"]]],
                "sortBy": [["systemFieldName": "createdTimestamp", "ascending": false]]
            ], "resultsLimit": 1
        ], allowsSignIn: allowsSignIn)
        guard let record = try records(in: response).first else { return nil }
        return try await domain(from: record)
    }

    func fetchMyRequests() async throws -> [PlantationReviewRequest] {
        // Same visibility and result limit as the native reference repository.
        let response = try await send("records/query", body: [
            "query": ["recordType": PlantationRecordCKAdapter.recordType,
                      "sortBy": [["systemFieldName": "createdTimestamp", "ascending": false]]],
            "resultsLimit": 50
        ], allowsSignIn: false)
        var result: [PlantationReviewRequest] = []
        for record in try records(in: response) { result.append(try await domain(from: record)) }
        return result
    }

    func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    if let latest = try? await fetchRequest(for: gardenID) {
                        continuation.yield(latest)
                        if latest.status == .completed { break }
                    }
                    do { try await Task.sleep(for: .seconds(5)) } catch { break }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func send(_ operation: String, body: [String: Any], allowsSignIn: Bool) async throws -> [String: Any] {
        try configuration.validate()
        await acquireRequest()
        defer { releaseRequest() }
        try Task.checkCancellation()
        for attempt in 0...1 {
            var request = URLRequest(url: try requestURL(operation))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, http) = try await transport(request)
            try Task.checkCancellation()
            guard let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw CloudKitWebError.invalidResponse
            }
            // Authentication tokens may rotate after each request. Never reuse a spent token.
            webAuthToken = response["ckWebAuthToken"] as? String
            let nestedError = (response["records"] as? [[String: Any]])?.first { $0["serverErrorCode"] != nil }
            let error = response["serverErrorCode"] != nil ? response : nestedError
            if let error, let code = error["serverErrorCode"] as? String {
                if code == "AUTHENTICATION_REQUIRED", allowsSignIn, attempt == 0,
                   let redirect = error["redirectURL"] as? String, let url = URL(string: redirect) {
                    webAuthToken = try await authenticate(url)
                    continue
                }
                throw CloudKitWebError.server(code)
            }
            guard (200...299).contains(http.statusCode) else {
                throw CloudKitWebError.server("HTTP \(http.statusCode)")
            }
            return response
        }
        throw CloudKitWebError.server("AUTHENTICATION_REQUIRED")
    }

    private func requestURL(_ operation: String) throws -> URL {
        let base = "https://api.apple-cloudkit.com/database/1/\(configuration.containerIdentifier)/\(configuration.environment.rawValue)/public/\(operation)"
        var components = URLComponents(string: base)!
        var items = [("ckAPIToken", configuration.apiToken)]
        if let webAuthToken { items.append(("ckWebAuthToken", webAuthToken)) }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        components.percentEncodedQuery = items.map { key, value in
            key + "=" + value.addingPercentEncoding(withAllowedCharacters: allowed)!
        }.joined(separator: "&")
        guard let url = components.url else { throw CloudKitWebError.invalidResponse }
        return url
    }

    private func records(in response: [String: Any]) throws -> [[String: Any]] {
        guard let records = response["records"] as? [[String: Any]] else { throw CloudKitWebError.invalidResponse }
        return records
    }

    private func domain(from record: [String: Any]) async throws -> PlantationReviewRequest {
        var assetURL: URL?
        if let source = CloudKitWebRecordAdapter.assetDownloadURL(in: record) {
            let folder = URL.applicationSupportDirectory.appending(path: "ReviewImages")
            let digest = SHA256.hash(data: Data(source.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
            let destination = folder.appending(path: digest + ".png")
            if !FileManager.default.fileExists(atPath: destination.path) {
                let (temporary, response) = try await URLSession.shared.download(from: source)
                defer { try? FileManager.default.removeItem(at: temporary) }
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw CloudKitWebError.invalidResponse
                }
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: temporary, to: destination)
            }
            assetURL = destination
        }
        return try mapper.toDomain(from: CloudKitWebRecordAdapter.decode(record, assetURL: assetURL))
    }

    private func acquireRequest() async {
        if requestInFlight { await withCheckedContinuation { waiters.append($0) } }
        else { requestInFlight = true }
    }

    private func releaseRequest() {
        if waiters.isEmpty { requestInFlight = false }
        else { waiters.removeFirst().resume() }
    }
}
