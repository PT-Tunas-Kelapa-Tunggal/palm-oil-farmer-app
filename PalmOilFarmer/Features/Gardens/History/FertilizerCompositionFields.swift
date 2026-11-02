import SwiftUI

struct FertilizerCompositionFields: View {
    @Binding var composition: FertilizerComposition
    let draftID: UUID
    var focusedField: FocusState<FertilizerField?>.Binding? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8),
              count: dynamicTypeSize.isAccessibilitySize ? 2 : 4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Komposisi").font(.headline).foregroundStyle(.secondary)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                nutrient("Nitrogen", value: $composition.nitrogen, kind: .nitrogen)
                nutrient("Fosfor", value: $composition.phosphorus, kind: .phosphorus)
                nutrient("Kalium", value: $composition.potassium, kind: .potassium)
                nutrient("Magnesium", value: $composition.magnesium, kind: .magnesium)
            }
            Text("Lihat angka di kemasan. Contoh: NPK 15-15-15 berarti N 15%, P 15%, K 15%.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func nutrient(_ title: String, value: Binding<Double?>,
                          kind: FertilizerField.Kind) -> some View {
        let id = FertilizerField(draftID: draftID, kind: kind)
        return VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Group {
                    if let focusedField {
                        input(title, value: value).focused(focusedField, equals: id)
                    } else {
                        input(title, value: value)
                    }
                }
                Text("%").foregroundStyle(.secondary).fontWeight(.regular)
            }
            .font(.title3.weight(.semibold))
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .background(GardenFlowStyle.background, in: RoundedRectangle(cornerRadius: 12))
        }
        .id(id)
    }

    private func input(_ title: String, value: Binding<Double?>) -> some View {
        TextField("0", value: value, format: .number)
            .keyboardType(.decimalPad)
            .accessibilityLabel("\(title), persen")
    }
}

#Preview("Komposisi NPK", traits: .sizeThatFitsLayout) {
    @Previewable @State var composition = FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15)
    FertilizerCompositionFields(composition: $composition, draftID: UUID())
        .padding(16)
        .frame(width: 370)
        .background(GardenFlowStyle.card)
}
