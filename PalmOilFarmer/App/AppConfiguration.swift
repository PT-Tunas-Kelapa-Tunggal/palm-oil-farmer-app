import Foundation

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
}

