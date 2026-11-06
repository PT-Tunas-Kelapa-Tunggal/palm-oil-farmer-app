import SwiftUI

/// Owns only the layout of the four custom percentage fields.
struct NPKCompositionInputView: View {
    let draftID: UUID
    @Binding var composition: FertilizerComposition
    var focusedField: FocusState<GardenProfileEditorField?>.Binding
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Komposisi").font(.body.weight(.semibold)).foregroundStyle(.secondary)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8),
                                count: dynamicTypeSize.isAccessibilitySize ? 1 : 4)
            LazyVGrid(columns: columns, spacing: 8) {
                nutrient("Nitrogen", value: $composition.nitrogen, kind: .nitrogen)
                nutrient("Fosfor", value: $composition.phosphorus, kind: .phosphorus)
                nutrient("Kalium", value: $composition.potassium, kind: .potassium)
                nutrient("Magnesium", value: $composition.magnesium, kind: .magnesium)
            }
            Text("Lihat angka di kemasan. Contoh: NPK 15-15-15 berarti N 15%, P 15%, K 15%.")
                .font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func nutrient(_ title: String, value: Binding<Double?>,
                          kind: GardenProfileEditorField.Nutrient) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                TextField("0", value: value, format: .number)
                    .fontWeight(.semibold)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: .fertilizerNutrient(draftID, kind))
                    .accessibilityLabel("\(title), persen")
                Text("%").foregroundStyle(.secondary)
            }
            .font(.title3).padding(8).frame(minHeight: 44)
            .background(GardenProfileStyle.formBackground, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

#if DEBUG
private struct NPKCompositionInputCanvas: View {
    @State private var draftID = UUID()
    @State private var composition = FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15)
    @FocusState private var focusedField: GardenProfileEditorField?

    var body: some View {
        NPKCompositionInputView(draftID: draftID, composition: $composition, focusedField: $focusedField)
            .padding().environment(\.locale, Locale(identifier: "id_ID"))
    }
}

#Preview("Komposisi NPK · Empat unsur", traits: .sizeThatFitsLayout) {
    NPKCompositionInputCanvas().frame(width: 402)
}
#Preview("Komposisi NPK · Teks besar", traits: .sizeThatFitsLayout) {
    NPKCompositionInputCanvas().frame(width: 320)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
