import Foundation
import SwiftData

/// Central runtime access to configuration values injected at build time from Xcode build settings.
public enum AppConfiguration {
    /// CloudKit container identifier injected at build time from `$(CLOUDKIT_CONTAINER_ID)`.
    /// Halts execution immediately if Developer.xcconfig is missing or unconfigured.
    public static var cloudKitContainerIdentifier: String {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "CKContainerIdentifier") as? String,
              !identifier.isEmpty,
              !identifier.hasPrefix("$(") else {
            fatalError("Missing required configuration: 'CKContainerIdentifier' is not set. Please ensure CLOUDKIT_CONTAINER_ID is configured in Developer.xcconfig.")
        }
        return identifier
    }

    /// CloudKit environment mode injected at build time from `$(CLOUDKIT_ENVIRONMENT)`.
    public static var cloudKitEnvironment: String {
        guard let env = Bundle.main.object(forInfoDictionaryKey: "CKEnvironment") as? String,
              !env.isEmpty,
              !env.hasPrefix("$(") else {
            fatalError("Missing required configuration: 'CKEnvironment' is not set. Please ensure CLOUDKIT_ENVIRONMENT is configured in Xcode build settings.")
        }
        return env
    }

    /// Sandboxed local storage directory strictly isolated by CloudKit container and environment.
    public static var environmentStorageDirectory: URL {
        let base = URL.documentsDirectory
            .appending(path: cloudKitContainerIdentifier)
            .appending(path: cloudKitEnvironment)
        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }

    /// Local SwiftData store file URL partitioned by environment.
    public static var swiftDataStoreURL: URL {
        environmentStorageDirectory.appending(path: "DraftPlantations.store")
    }

    /// Instantiates the SwiftData ModelContainer partitioned to the active CloudKit container and environment.
    public static func makeModelContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([DraftPlantationRequest.self])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                url: swiftDataStoreURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
        }
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }
}

