import SwiftUI

struct FertilizerInputCard: View {
    @Binding var draft: FertilizerInputDraft
    var focusedField: FocusState<GardenProfileEditorField?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Jenis pupuk").font(.body.weight(.semibold)).foregroundStyle(.secondary)
                Menu {
                    Picker("Jenis pupuk", selection: $draft.kind) {
                        Text("Pilih Jenis Pupuk").tag(FertilizerType.unselected)
                        ForEach(options, id: \.self) { kind in
                            Text(FertilizerCatalogue.displayName(for: kind)).tag(kind)
                        }
                    }
                } label: {
                    HStack {
                        Text(draft.kind == .unselected ? "Pilih Jenis Pupuk" : FertilizerCatalogue.displayName(for: draft.kind))
                            .foregroundStyle(draft.name.isEmpty ? .tertiary : .primary)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.tertiary)
                    }
                    .font(.title3.weight(draft.name.isEmpty ? .regular : .semibold))
                    .frame(minHeight: 41).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Jenis pupuk").accessibilityValue(draft.name.isEmpty ? "Belum dipilih" : draft.name)
            }
            .padding(.top, 16).padding(.bottom, 8)
            Divider()
            if draft.kind == .npk {
                NPKCompositionInputView(draftID: draft.id, composition: $draft.composition,
                                            focusedField: focusedField)
                    .padding(.vertical, 16)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Dosis per pohon").font(.body.weight(.semibold)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    TextField("cth: 0,5", value: $draft.doseKgPerTree, format: .number)
                        .keyboardType(.decimalPad)
                        .focused(focusedField, equals: .fertilizerDose(draft.id))
                        .accessibilityLabel("Dosis \(draft.name) per pohon, kilogram")
                    Text("kg").fontWeight(.regular)
                }
                .font(.title3.weight(.semibold)).frame(minHeight: 41)
            }
            .padding(.top, 16).padding(.bottom, 8)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16)
        .background(GardenProfileStyle.field, in: RoundedRectangle(cornerRadius: 24))
    }

    private var options: [FertilizerType] {
        let kinds = FertilizerCatalogue.options
        return draft.kind == .unselected || kinds.contains(draft.kind) ? kinds : kinds + [draft.kind]
    }
}

#if DEBUG
private struct FertilizerInputCardCanvas: View {
    @State private var draft = FertilizerInputDraft(record: FertilizerRecord(
        name: "NPK", bagWeightKg: nil, bagCount: nil, doseKgPerTree: 0.5,
        composition: FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15)))
    @FocusState private var focusedField: GardenProfileEditorField?

    var body: some View {
        FertilizerInputCard(draft: $draft, focusedField: $focusedField)
            .padding(12)
            .environment(\.locale, Locale(identifier: "id_ID"))
    }
}

#Preview("NPK · Custom", traits: .sizeThatFitsLayout) {
    FertilizerInputCardCanvas().frame(width: 402)
}

#Preview("NPK · Accessibility", traits: .sizeThatFitsLayout) {
    FertilizerInputCardCanvas().frame(width: 320)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
