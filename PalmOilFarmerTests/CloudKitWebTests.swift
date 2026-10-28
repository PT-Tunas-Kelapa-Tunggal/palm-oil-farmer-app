import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct CloudKitWebTests {
    @Test func authenticatedSubmissionWritesTheOperatorsRecordAndRotatesToken() async throws {
        let request = sampleRequest()
        let record = try CloudKitWebRecordAdapter.encode(PlantationDomainMapper().toDTO(from: request))
        let spy = WebTransportSpy(responses: [
            ["serverErrorCode": "AUTHENTICATION_REQUIRED", "redirectURL": "https://idmsa.apple.com/signin"],
            ["records": [record], "ckWebAuthToken": "rotated+/="],
            ["records": [record]]
        ])
        var signIns = 0
        let repository = CloudKitWebFarmerReviewRepository(
            configuration: configuration(), transport: spy.send,
            authenticate: { url in
                #expect(url.host == "idmsa.apple.com")
                signIns += 1
                return "signed-in+/="
            })
        let saved = try await repository.submitRequest(request)
        #expect(saved.id == request.id)
        #expect(saved.garden.id == request.garden.id)
        #expect(saved.status == .submitted)
        #expect(signIns == 1)
        #expect(spy.requests.count == 2)
        let submitted = spy.requests[1]
        #expect(submitted.url?.path == "/database/1/iCloud.com.testaccount.Reviews/development/public/records/modify")
        #expect(queryItem("ckWebAuthToken", in: submitted) == "signed-in+/=")
        #expect(submitted.url?.absoluteString.contains("%2B%2F%3D") == true)
        let submittedBody = try #require(submitted.httpBody)
        let body = try #require(try JSONSerialization.jsonObject(with: submittedBody) as? [String: Any])
        let operation = try #require((body["operations"] as? [[String: Any]])?.first)
        #expect(operation["operationType"] as? String == "create")
        let outbound = try #require(operation["record"] as? [String: Any])
        #expect(outbound["recordType"] as? String == "PlantationScanRequest")
        let fields = try #require(outbound["fields"] as? [String: [String: Any]])
        #expect(fields["submittedAt"]?["type"] as? String == "TIMESTAMP")
        #expect(fields["submittedAt"]?["value"] as? Double == 1_700_000_000_000)
        #expect(fields["statusCode"]?["type"] as? String == "INT64")
        #expect(fields["statusCode"]?["value"] as? Int == 0)
        let boundary = try #require(fields["boundaryJSON"]?["value"] as? String)
        let points = try #require(try JSONSerialization.jsonObject(with: Data(boundary.utf8)) as? [[String: Double]])
        #expect(points.first?["lat"] == 1.1)
        #expect(points.first?["lon"] == 104.4)
        _ = try await repository.fetchRequest(for: request.garden.id)
        #expect(queryItem("ckWebAuthToken", in: spy.requests[2]) == "rotated+/=")
        let queryData = try #require(spy.requests[2].httpBody)
        let queryBody = try #require(try JSONSerialization.jsonObject(with: queryData) as? [String: Any])
        let query = try #require(queryBody["query"] as? [String: Any])
        let filter = try #require((query["filterBy"] as? [[String: Any]])?.first)
        #expect(filter["fieldName"] as? String == "gardenID")
        #expect((filter["fieldValue"] as? [String: Any])?["value"] as? String == request.garden.id.uuidString)
        #expect(queryBody["resultsLimit"] as? Int == 1)
    }

    @Test func operatorTimestampAndResultJSONArePreserved() throws {
        let request = sampleRequest()
        var record = try CloudKitWebRecordAdapter.encode(PlantationDomainMapper().toDTO(from: request))
        var fields = try #require(record["fields"] as? [String: [String: Any]])
        fields["statusCode"] = ["type": "INT64", "value": 3]
        fields["completedAt"] = ["type": "TIMESTAMP", "value": 1_700_086_400_000.0]
        fields["resultJSON"] = ["type": "STRING", "value": #"{"completedAt":721779200,"nutrients":[],"costs":[],"totalCostFormatted":"Rp 500.000","areas":[{"areaID":"A","periods":[]}]}"#]
        record["fields"] = fields
        let result = try PlantationDomainMapper().toDomain(from: CloudKitWebRecordAdapter.decode(record))
        #expect(result.status == .completed)
        #expect(result.timeline.completedAt == Date(timeIntervalSince1970: 1_700_086_400))
        #expect(result.result?.totalCostFormatted == "Rp 500.000")
        #expect(result.result?.allocationAreas.first?.id == "A")
    }

    @Test func perRecordPermissionFailureIsNotReportedAsSuccess() async {
        let spy = WebTransportSpy(responses: [["records": [["serverErrorCode": "ACCESS_DENIED"]]]])
        let repository = CloudKitWebFarmerReviewRepository(configuration: configuration(), transport: spy.send)
        do {
            _ = try await repository.submitRequest(sampleRequest())
            Issue.record("A rejected CloudKit record must not appear submitted.")
        } catch {
            #expect(error.localizedDescription.contains("ACCESS_DENIED"))
        }
    }

    @Test func missingTokenDoesNotAttemptNetworkOrSimulateASubmission() async {
        let spy = WebTransportSpy(responses: [])
        let repository = CloudKitWebFarmerReviewRepository(
            configuration: CloudKitWebConfiguration(containerIdentifier: "iCloud.com.testaccount.Reviews", apiToken: "REPLACE_WITH_TOKEN", environment: .development),
            transport: spy.send)
        do {
            _ = try await repository.submitRequest(sampleRequest())
            Issue.record("A missing API token must block submission.")
        } catch {
            #expect(error is CloudKitWebError)
            #expect(spy.requests.isEmpty)
        }
    }

    @Test func profileRefreshDoesNotPresentAnUnexpectedLogin() async {
        let spy = WebTransportSpy(responses: [[
            "serverErrorCode": "AUTHENTICATION_REQUIRED", "redirectURL": "https://idmsa.apple.com/signin"
        ]])
        var signIns = 0
        let repository = CloudKitWebFarmerReviewRepository(configuration: configuration(), transport: spy.send,
            authenticate: { _ in signIns += 1; return "token" })
        do {
            _ = try await repository.fetchRequest(for: UUID())
            Issue.record("Authentication failure must remain visible to the caller.")
        } catch { #expect(signIns == 0) }
    }

    @Test func loginCallbackAcceptsOnlyTheConfiguredAddress() {
        #expect(CloudKitWebSignIn.isAppleSignInURL(URL(string: "https://idmsa.apple.com/signin")!))
        #expect(!CloudKitWebSignIn.isAppleSignInURL(URL(string: "https://apple.com.attacker.example/signin")!))
        #expect(!CloudKitWebSignIn.isAppleSignInURL(URL(string: "http://idmsa.apple.com/signin")!))
        #expect(CloudKitWebSignIn.token(from: URL(string: "https://localhost/krops-cloudkit/auth?ckWebAuthToken=abc%2B%2F%3D")!) == "abc+/=")
        #expect(CloudKitWebSignIn.token(from: URL(string: "https://attacker.example/krops-cloudkit/auth?ckWebAuthToken=wrong")!) == nil)
        #expect(CloudKitWebSignIn.token(from: URL(string: "https://localhost/another-path?ckWebAuthToken=wrong")!) == nil)
    }

    @Test func explicitRefreshCanSignInAgainAfterReopeningTheApp() async throws {
        let request = sampleRequest()
        let record = try CloudKitWebRecordAdapter.encode(PlantationDomainMapper().toDTO(from: request))
        let spy = WebTransportSpy(responses: [
            ["serverErrorCode": "AUTHENTICATION_REQUIRED", "redirectURL": "https://idmsa.apple.com/signin"],
            ["records": [record]]
        ])
        var signIns = 0
        let repository = CloudKitWebFarmerReviewRepository(configuration: configuration(), transport: spy.send,
            authenticate: { _ in signIns += 1; return "new-session-token" })
        let refreshed = try await repository.fetchRequest(for: request.garden.id, allowsSignIn: true)
        #expect(refreshed?.id == request.id)
        #expect(signIns == 1)
    }

    private func configuration() -> CloudKitWebConfiguration {
        CloudKitWebConfiguration(containerIdentifier: "iCloud.com.testaccount.Reviews", apiToken: "test-api-token", environment: .development)
    }

    private func queryItem(_ name: String, in request: URLRequest) -> String? {
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == name }?.value
    }

    private func sampleRequest() -> PlantationReviewRequest {
        PlantationReviewRequest(farmer: FarmerContact(name: "Uji", phone: "081234567890", address: "Desa Uji"),
            garden: GardenSummary(id: UUID(), name: "Kebun Uji", locationName: "Bintan", areaHectares: 1.2),
            boundary: [CoordinatePoint(latitude: 1.1, longitude: 104.4)],
            agronomy: AgronomicProfile(plantingYear: 2016, soilType: "Gambut"),
            timeline: ReviewTimeline(submittedAt: Date(timeIntervalSince1970: 1_700_000_000)))
    }
}

@MainActor
private final class WebTransportSpy {
    private(set) var requests: [URLRequest] = []
    private var responses: [[String: Any]]

    init(responses: [[String: Any]]) { self.responses = responses }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        guard !responses.isEmpty else { throw URLError(.badServerResponse) }
        let response = responses.removeFirst()
        return (try JSONSerialization.data(withJSONObject: response),
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}
