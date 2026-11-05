import Foundation

extension GardenDraft {
    var title: String {
        subtitle.isEmpty || subtitle == name ? name : "\(name), \(subtitle)"
    }
}
