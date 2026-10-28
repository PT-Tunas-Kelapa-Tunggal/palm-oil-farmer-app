import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct ServiceConfigurationTests {
    @Test func builtHostAppContainsExpandedServiceConfiguration() throws {
        let configuration = try CloudKitServiceConfiguration.load()
        #expect(configuration.containerIdentifier.hasPrefix("iCloud."))
    }

    @Test func nativeModeLoadsTheDevelopersOwnContainerWithoutAToken() throws {
        let configuration = try CloudKitServiceConfiguration(info: settings())
        #expect(configuration.transport == .native)
        #expect(configuration.containerIdentifier == "iCloud.com.alice.Krops")
        #expect(configuration.webEnvironment == .development)
    }

    @Test func anotherDeveloperCanSelectADifferentBackend() throws {
        var info = settings()
        info["KropsCloudKitContainer"] = "iCloud.com.bob.Krops"
        info["KropsReviewTransport"] = "web"
        info["KropsWebEnvironment"] = "production"
        let configuration = try CloudKitServiceConfiguration(info: info)
        #expect(configuration.containerIdentifier == "iCloud.com.bob.Krops")
        #expect(configuration.transport == .web)
        #expect(configuration.webEnvironment == .production)
    }

    @Test(arguments: ["", "$(KROPS_CLOUDKIT_CONTAINER)", "iCloud.com.account/path", "iCloud.com.account?token=x", "iCloud.com..account"])
    func invalidOrUnexpandedContainerCannotBecomeANetworkDestination(_ container: String) {
        var info = settings()
        info["KropsCloudKitContainer"] = container
        #expect(throws: ServiceConfigurationError.self) {
            try CloudKitServiceConfiguration(info: info)
        }
    }

    @Test func missingModeDoesNotSilentlyChooseAnotherTransport() {
        var info = settings()
        info.removeValue(forKey: "KropsReviewTransport")
        #expect(throws: ServiceConfigurationError.self) {
            try CloudKitServiceConfiguration(info: info)
        }
    }

    private func settings() -> [String: Any] {
        ["KropsCloudKitContainer": "iCloud.com.alice.Krops", "KropsReviewTransport": "native",
         "KropsWebEnvironment": "development"]
    }
}
