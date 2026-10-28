import SwiftUI

struct NutrientReferenceScreen: View {
    let reference: NutrientReference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(reference.title).font(.title2.bold())
                Text(reference.explanation).font(.subheadline)
                Text("Pupuk yang mengandung " + reference.title.components(separatedBy: " (")[0].lowercased())
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(reference.fertilizers) { fertilizer in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fertilizer.name).font(.headline)
                        Text(fertilizer.detail).font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    if fertilizer.id != reference.fertilizers.last?.id { Divider() }
                }
                Text(reference.note).font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
