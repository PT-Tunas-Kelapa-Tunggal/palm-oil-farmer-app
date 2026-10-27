import SwiftUI

struct FertilizerEntryCard: View {
    @Binding var draft: FertilizerDraft
    let onSelectType: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FormSelectionRow(
                title: "Jenis Pupuk", placeholder: "Pilih jenis pupuk",
                value: draft.name.isEmpty ? nil : draft.name, action: onSelectType
            )
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
}
