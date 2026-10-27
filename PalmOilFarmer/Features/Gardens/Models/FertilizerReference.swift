import Foundation

struct FertilizerReference: Identifiable, Codable {
    let name: String
    let detail: String
    var id: String { name }
}
