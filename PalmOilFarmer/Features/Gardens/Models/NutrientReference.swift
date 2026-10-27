import Foundation

struct NutrientReference: Identifiable, Codable {
    let id: String
    let title: String
    let explanation: String
    let fertilizers: [FertilizerReference]
    let note: String
}
