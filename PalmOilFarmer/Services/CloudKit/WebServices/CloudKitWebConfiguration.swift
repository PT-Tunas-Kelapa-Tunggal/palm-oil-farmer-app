import Foundation

struct CloudKitWebConfiguration {
    typealias Environment = CloudKitServiceConfiguration.Environment
    static let callbackURL = URL(string: "https://localhost/krops-cloudkit/auth")!

    let containerIdentifier: String
    let apiToken: String
    let environment: Environment

    func validate() throws {
        guard !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !apiToken.contains("REPLACE_"),
              CloudKitServiceConfiguration.isValidContainerIdentifier(containerIdentifier) else {
            throw CloudKitWebError.configurationMissing
        }
    }

    static func load(services: CloudKitServiceConfiguration, bundle: Bundle = .main) throws -> Self {
        struct Credentials: Decodable { let apiToken: String }
        guard let url = bundle.url(forResource: "CloudKitWeb.local", withExtension: "plist") else {
            throw CloudKitWebError.configurationMissing
        }
        let credentials = try PropertyListDecoder().decode(Credentials.self, from: Data(contentsOf: url))
        let configuration = Self(containerIdentifier: services.containerIdentifier, apiToken: credentials.apiToken,
                                 environment: services.webEnvironment)
        try configuration.validate()
        return configuration
    }
}

enum CloudKitWebError: LocalizedError {
    case configurationMissing, invalidResponse, signInUnavailable, invalidSignInURL
    case server(String)

    var errorDescription: String? {
        switch self {
        case .configurationMissing: "Layanan peninjauan belum terhubung ke operator. Hubungi pengelola aplikasi untuk mengaktifkan pengiriman."
        case .invalidResponse: "Respons layanan peninjauan tidak lengkap."
        case .signInUnavailable: "Login iCloud belum dapat dibuka. Coba lagi dari aplikasi."
        case .invalidSignInURL: "Alamat login iCloud tidak valid."
        case .server(let code): "Layanan peninjauan belum dapat memproses permintaan (\(code))."
        }
    }
}
