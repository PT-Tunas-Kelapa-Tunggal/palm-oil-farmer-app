import Foundation

/// Values are supplied once by Config/Services.xcconfig and its ignored local override.
struct CloudKitServiceConfiguration {
    enum Transport: String { case native, web }
    enum Environment: String { case development, production }

    let containerIdentifier: String
    let transport: Transport
    let webEnvironment: Environment

    init(info: [String: Any]) throws {
        guard let identifier = info["KropsCloudKitContainer"] as? String,
              Self.isValidContainerIdentifier(identifier),
              let mode = info["KropsReviewTransport"] as? String, let transport = Transport(rawValue: mode),
              let environment = info["KropsWebEnvironment"] as? String,
              let webEnvironment = Environment(rawValue: environment) else {
            throw ServiceConfigurationError.invalidConfiguration
        }
        containerIdentifier = identifier
        self.transport = transport
        self.webEnvironment = webEnvironment
    }

    static func load(bundle: Bundle = .main) throws -> Self {
        try Self(info: bundle.infoDictionary ?? [:])
    }

    static func isValidContainerIdentifier(_ identifier: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")
        return identifier.hasPrefix("iCloud.") && identifier.count > 7
            && identifier.unicodeScalars.allSatisfy { allowed.contains($0) }
            && !identifier.contains("..")
    }
}

enum ServiceConfigurationError: LocalizedError {
    case invalidConfiguration

    var errorDescription: String? {
        "Konfigurasi layanan belum lengkap. Periksa setup layanan aplikasi terlebih dahulu."
    }
}
