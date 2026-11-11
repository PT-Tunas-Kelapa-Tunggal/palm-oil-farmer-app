#if DEBUG
import Foundation

/// Dummy `GardenLocationAuthorizing`: previews never show the system location prompt.
@MainActor
struct DummyGardenLocationAuthorization: GardenLocationAuthorizing {
    func requestAuthorization() {}
}
#endif
