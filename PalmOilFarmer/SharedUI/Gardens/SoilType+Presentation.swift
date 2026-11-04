import Foundation

extension SoilType {
    var displayName: String {
        self == .other ? rawValue : "Tanah " + rawValue
    }
}
