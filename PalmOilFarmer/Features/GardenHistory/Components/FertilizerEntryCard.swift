import SwiftUI

struct FertilizerEntryCard: View {
    @Binding var draft: FertilizerDraft
    let onSelectType: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FormSelectionRow(
                title: "Jenis Pupuk", placeholder: "Pilih jenis pupuk",
                value: draft.name.isEmpty ? nil : draft.displayName, action: onSelectType
            )
            if draft.usesCustomNPKComposition {
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    fieldTitle("Komposisi NPK (% hara)")
                    HStack(spacing: 12) {
                        compositionField("N", binding: $draft.nitrogenPercent)
                        compositionField("P₂O₅", binding: $draft.phosphatePercent)
                        compositionField("K₂O", binding: $draft.potashPercent)
                    }
                    if draft.requiresMagnesiumComposition {
                        compositionField("MgO", binding: $draft.magnesiumPercent)
                    }
                    Text("Masukkan persentase sesuai label pupuk. Contoh NPK 12-6-32: N 12, P₂O₅ 6, K₂O 32.")
                        .font(.footnote).fontWeight(.regular).foregroundStyle(.secondary)
                }
            } else if draft.name == FertilizerCatalogue.unknownNPK {
                Divider()
                Text("Komposisi tidak perlu diisi. Gunakan informasi berat dan dosis pada label pupuk jika tersedia.")
                    .font(.subheadline).fontWeight(.regular).foregroundStyle(.secondary)
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                fieldTitle("Berat per karung")
                HStack {
                    TextField("cth: 50", value: $draft.bagWeightKg, format: .number).keyboardType(.decimalPad)
                        .accessibilityLabel("Berat per karung, kilogram")
                    Text("kg").fontWeight(.regular)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                fieldTitle("Jumlah karung")
                HStack {
                    TextField("cth: 6", value: $draft.bagCount, format: .number).keyboardType(.numberPad)
                        .accessibilityLabel("Jumlah karung")
                    Text("sak").fontWeight(.regular)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                fieldTitle("Dosis per pohon")
                HStack {
                    TextField("cth: 1.5", value: $draft.doseKgPerTree, format: .number).keyboardType(.decimalPad)
                        .accessibilityLabel("Dosis per pohon, kilogram")
                    Text("kg").fontWeight(.regular)
                }
            }
        }
        .font(.title3.weight(.semibold))
        .padding(16)
        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 24))
    }

    private func fieldTitle(_ title: String) -> some View {
        Text(title).font(.headline).foregroundStyle(.secondary)
    }

    private func compositionField(_ title: String, binding: Binding<Double?>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            TextField("%", value: binding, format: .number)
                .keyboardType(.decimalPad)
                .accessibilityLabel("Persentase \(title)")
                .padding(10)
                .background(.background, in: RoundedRectangle(cornerRadius: 10))
        }
        .fontWeight(.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
