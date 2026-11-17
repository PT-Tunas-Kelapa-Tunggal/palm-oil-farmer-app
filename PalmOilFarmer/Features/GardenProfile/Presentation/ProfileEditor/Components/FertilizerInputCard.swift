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
                        ForEach(primaryOptions, id: \.self) { kind in
                            Text(FertilizerCatalogue.displayName(for: kind)).tag(kind)
                        }
                        Divider()
                        Text(FertilizerCatalogue.displayName(for: .other)).tag(FertilizerType.other)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image("ProfileSeedling").resizable().scaledToFit().frame(width: 22, height: 24).foregroundStyle(.secondary)
                        Text(draft.kind == .unselected ? "Pilih Jenis Pupuk" : FertilizerCatalogue.displayName(for: draft.kind))
                            .foregroundStyle(draft.name.isEmpty ? .tertiary : .primary)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.tertiary)
                    }
                    .font(.title3)
                    .padding(.horizontal, 14).frame(minHeight: 52)
                    .background(KropsTheme.surfaceCardRaised, in: RoundedRectangle(cornerRadius: 12)).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Jenis pupuk").accessibilityValue(draft.name.isEmpty ? "Belum dipilih" : draft.name)
            }
            .padding(.top, 16).padding(.bottom, 8)
            if draft.kind == .npk {
                NPKCompositionInputView(draftID: draft.id, composition: $draft.composition,
                                            focusedField: focusedField)
                    .padding(.top, 8)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Dosis per pohon setiap pemupukan").font(.body.weight(.semibold)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Image(systemName: "chart.dots.scatter").foregroundStyle(.secondary)
                    TextField("cth: 0,5", value: $draft.doseKgPerTree, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .focused(focusedField, equals: .fertilizerDose(draft.id))
                        .accessibilityLabel("Dosis \(draft.name) per pohon, kilogram")
                    Text("kg").font(.body).foregroundStyle(.secondary)
                }
                .font(.title3).padding(.horizontal, 14).frame(minHeight: 52)
                .background(KropsTheme.surfaceCardRaised, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, draft.kind == .npk ? 16 : 8).padding(.bottom, 8)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16).padding(.bottom, 8)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(KropsTheme.surfaceCard)
                .onTapGesture { focusedField.wrappedValue = nil }
        }
    }

    private var primaryOptions: [FertilizerType] {
        let kinds: [FertilizerType] = [.urea, .za, .npk, .sp36, .kcl, .dolomite, .kieserite, .manure]
        return draft.kind == .unselected || draft.kind == .other || kinds.contains(draft.kind) ? kinds : kinds + [draft.kind]
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
