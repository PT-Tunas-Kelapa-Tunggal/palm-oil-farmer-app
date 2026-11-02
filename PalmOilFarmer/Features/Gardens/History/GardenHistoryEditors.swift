import SwiftUI

/// A numeric field in one fertilizer card; used for focus and scrolling.
struct FertilizerField: Hashable {
    enum Kind: CaseIterable { case nitrogen, phosphorus, potassium, magnesium, dose }
    let draftID: UUID
    let kind: Kind
}

struct FertilizerHistoryEditor: View {
    @State private var drafts: [FertilizerDraft]
    @State private var errorMessage: String?
    @State private var frequency: Int
    private let gardenID: UUID?
    private let detailsStore: LocalFertilizerFormStore
    @FocusState private var focusedField: FertilizerField?
    let onSave: ([FertilizerRecord], Int) -> Bool
    var onContinue: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    init(records: [FertilizerRecord], includesEmptyDraft: Bool = false,
         gardenID: UUID? = nil, frequencyPerYear: Int? = nil, detailsStore: LocalFertilizerFormStore = LocalFertilizerFormStore(),
         onContinue: (() -> Void)? = nil,
         onSave: @escaping ([FertilizerRecord], Int) -> Bool) {
        self.gardenID = gardenID
        self.detailsStore = detailsStore
        let details = gardenID.map { detailsStore.load(gardenID: $0) } ?? FertilizerFormDetails()
        _frequency = State(initialValue: min(max(frequencyPerYear ?? details.frequencyPerYear, 1), 12))
        var drafts = records.map { record in
            var draft = FertilizerDraft(record: record)
            if record.composition == nil, let composition = details.compositions[record.id] {
                draft.composition = composition
            }
            return draft
        }
        if drafts.isEmpty || includesEmptyDraft { drafts.append(FertilizerDraft()) }
        _drafts = State(initialValue: drafts)
        self.onSave = onSave
        self.onContinue = onContinue
    }

    /// Existing preview callers can keep using the records-only callback.
    init(records: [FertilizerRecord], includesEmptyDraft: Bool = false,
         gardenID: UUID? = nil, frequencyPerYear: Int? = nil,
         detailsStore: LocalFertilizerFormStore = LocalFertilizerFormStore(),
         onContinue: (() -> Void)? = nil,
         onSave: @escaping ([FertilizerRecord]) -> Bool) {
        self.init(records: records, includesEmptyDraft: includesEmptyDraft,
                  gardenID: gardenID, frequencyPerYear: frequencyPerYear,
                  detailsStore: detailsStore, onContinue: onContinue,
                  onSave: { records, _ in onSave(records) })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GardenHistoryFormHeader(step: 1, onBack: { dismiss() }, onConfirm: save,
                                        confirmationTitle: onContinue == nil ? "Simpan" : "Lanjut")
                ScrollViewReader { reader in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Riwayat Pemupukan").font(.title.bold()).padding(.horizontal, 8)
                            HStack {
                                Text("Frekuensi Pemupukan\ndalam setahun")
                                    .font(.headline)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 8)
                                HarvestFrequencyStepper(value: $frequency, range: 1...12,
                                                        accessibilityTitle: "Frekuensi pemupukan", period: "satu tahun")
                            }
                            .padding(16)
                            .frame(minHeight: 76)
                            .background(GardenFlowStyle.card, in: RoundedRectangle(cornerRadius: 24))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Jenis Pupuk").font(.headline)
                                Text("Data pupuk yang diaplikasikan di kebun ini dalam periode pemupukan terakhir.")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            ForEach($drafts) { $draft in
                                FertilizerEntryCard(draft: $draft, focusedField: $focusedField)
                                .contextMenu {
                                    Button("Hapus jenis pupuk", role: .destructive) {
                                        drafts.removeAll { $0.id == draft.id }
                                    }
                                }
                            }
                            Button {
                                let draft = FertilizerDraft()
                                drafts.append(draft)
                                focusedField = nil
                                withAnimation { reader.scrollTo(draft.id, anchor: .top) }
                            } label: {
                                Label("Tambah jenis pupuk", systemImage: "plus")
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(Color(uiColor: .systemGray4), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                    }
                    // Room below the last control so it can scroll clear of the keyboard and the home indicator.
                    .contentMargins(.bottom, 96, for: .scrollContent)
                    .scrollDismissesKeyboard(.immediately)
                    .onChange(of: focusedField) { _, field in
                        guard let field else { return }
                        withAnimation { reader.scrollTo(field, anchor: .center) }
                    }
                }
            }
            // A floating bar with a gap above the keyboard; the inset also lifts the scroll content clear of it.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if focusedField != nil {
                    KeyboardActionBar(onNext: nextField.map { next in { focusedField = next } },
                                      onDone: { focusedField = nil })
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: focusedField == nil)
            .containerBackground(.clear, for: .navigation)
            .toolbar(.hidden, for: .navigationBar)
            .alert("Riwayat belum tersimpan", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Mengerti", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(GardenFlowStyle.background)
    }

    private var nextField: FertilizerField? {
        let order = drafts.flatMap { draft in
            let kinds: [FertilizerField.Kind] = draft.isNPK
                ? [.nitrogen, .phosphorus, .potassium, .magnesium, .dose]
                : [.dose]
            return kinds.map { FertilizerField(draftID: draft.id, kind: $0) }
        }
        guard let focusedField, let index = order.firstIndex(of: focusedField), index + 1 < order.count else { return nil }
        return order[index + 1]
    }

    private func save() {
        focusedField = nil
        let filled = drafts.filter { !$0.isEmpty }
        guard filled.filter(\.isNPK).allSatisfy({ $0.composition.isValid }) else {
            errorMessage = "Isi komposisi N, P, dan K sesuai kemasan. Setiap nilai harus 0–100% dan total tidak boleh melebihi 100%."
            return
        }
        let records = filled.compactMap(\.record)
        guard records.count == filled.count else {
            errorMessage = "Pastikan jenis pupuk dan dosis sudah diisi dengan benar."
            return
        }
        if onSave(records, frequency) {
            if let gardenID { detailsStore.remove(gardenID: gardenID) }
            onContinue?()
            dismiss()
        } else {
            errorMessage = "Data tidak dapat disimpan di perangkat. Coba lagi."
        }
    }
}

struct FertilizerEntryCard: View {
    @Binding var draft: FertilizerDraft
    var focusedField: FocusState<FertilizerField?>.Binding? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Menu {
                ForEach(FertilizerCatalogue.names, id: \.self) { name in
                    Button {
                        focusedField?.wrappedValue = nil
                        draft.name = name
                    } label: {
                        if draft.name == name {
                            Label(name, systemImage: "checkmark")
                        } else {
                            Text(name)
                        }
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Jenis pupuk").font(.headline).foregroundStyle(.secondary)
                    HStack {
                        Text(draft.name.isEmpty ? "Pilih jenis pupuk" : draft.isNPK ? "NPK" : draft.name)
                            .font(.title3.weight(draft.isNPK ? .semibold : .regular))
                            .foregroundStyle(draft.name.isEmpty ? Color.secondary : Color.primary)
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .id(draft.id)
            Divider()
            if draft.isNPK {
                FertilizerCompositionFields(composition: $draft.composition, draftID: draft.id,
                                            focusedField: focusedField)
                    .padding(.bottom, 16)
            }
            numberField("Dosis per pohon", unit: "kg", kind: .dose,
                        accessibility: "Dosis per pohon, kilogram") {
                TextField("cth: 0,5", value: $draft.doseKgPerTree, format: .number).keyboardType(.decimalPad)
            }

        }
        .font(.title3.weight(.semibold))
        .padding(16)
        .background(GardenFlowStyle.card, in: RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private func numberField<Field: View>(_ title: String, unit: String,
                                          kind: FertilizerField.Kind, accessibility: String,
                                          @ViewBuilder field: () -> Field) -> some View {
        let id = FertilizerField(draftID: draft.id, kind: kind)
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            HStack {
                if let focusedField {
                    field().focused(focusedField, equals: id)
                } else {
                    field()
                }
                Text(unit).fontWeight(.regular)
            }
            .accessibilityLabel(accessibility)
        }
        .id(id)
    }
}

struct HarvestHistoryEditor: View {
    let onSave: (HarvestRecord) -> Bool
    var onBack: (() -> Void)? = nil
    @State private var frequency: Int
    @State private var weight: Double?
    @State private var showsError = false
    @Environment(\.dismiss) private var dismiss

    static let frequencyRange = 1...31

    init(record: HarvestRecord?, onBack: (() -> Void)? = nil, onSave: @escaping (HarvestRecord) -> Bool) {
        self.onSave = onSave
        self.onBack = onBack
        _frequency = State(initialValue: min(max(record?.frequencyPerMonth ?? 2, Self.frequencyRange.lowerBound),
                                             Self.frequencyRange.upperBound))
        _weight = State(initialValue: record?.latestWeightKg)
    }

    @FocusState private var isWeightFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            GardenHistoryFormHeader(step: 2, onBack: {
                onBack?()
                dismiss()
            }, onConfirm: save)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Riwayat Panen")
                        .font(.title.bold())
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    HStack {
                        Text("Frekuensi Panen dalam Sebulan")
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 12)
                        HarvestFrequencyStepper(value: $frequency, range: Self.frequencyRange)
                    }
                    .padding(16)
                    .frame(minHeight: 76)
                    .background(GardenFlowStyle.card, in: RoundedRectangle(cornerRadius: 24))

                    HStack {
                        Text("Rata-rata berat per panen")
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 12)
                        TextField("0", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isWeightFocused)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                            .frame(minWidth: 70, maxWidth: 110)
                            .accessibilityLabel("Rata-rata berat per panen, kilogram")
                        Text("kg").font(.title2.bold())
                    }
                    .padding(16)
                    .frame(minHeight: 76)
                    .background(GardenFlowStyle.card, in: RoundedRectangle(cornerRadius: 24))
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                if isWeightFocused {
                    KeyboardActionBar(onNext: nil, onDone: { isWeightFocused = false })
                }
            }
        }
        .background(GardenFlowStyle.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(GardenFlowStyle.background)
        .alert("Riwayat belum tersimpan", isPresented: $showsError) {
            Button("Mengerti", role: .cancel) {}
        }
    }

    private func save() {
        isWeightFocused = false
        guard let weight, Self.frequencyRange.contains(frequency), weight.isFinite, weight > 0 else { showsError = true; return }
        if onSave(HarvestRecord(frequencyPerMonth: frequency, latestWeightKg: weight)) {
            dismiss()
        } else { showsError = true }
    }
}

struct HarvestFrequencyStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var accessibilityTitle = "Frekuensi panen"
    var period = "satu bulan"

    var body: some View {
        HStack(spacing: 0) {
            stepButton("minus", label: "Kurangi", isEnabled: value > range.lowerBound) { value -= 1 }
            Text("\(value)")
                .font(.title2.bold())
                .monospacedDigit()
                .frame(minWidth: 32)
                .contentTransition(.numericText(value: Double(value)))
            stepButton("plus", label: "Tambah", isEnabled: value < range.upperBound) { value += 1 }
        }
        .animation(.snappy, value: value)
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue("\(value) kali dalam \(period)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment where value < range.upperBound: value += 1
            case .decrement where value > range.lowerBound: value -= 1
            default: break
            }
        }
    }

    private func stepButton(_ symbol: String, label: String, isEnabled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.4))
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

#if DEBUG
#Preview("Pemupukan · Filled", traits: .fixedLayout(width: 402, height: 1034)) {
    FertilizerHistoryEditor(
        records: [FertilizerRecord(name: "NPK", doseKgPerTree: 0.5,
                                   composition: FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15)),
                  FertilizerRecord(name: "Dolomit", doseKgPerTree: 0.5)],
        onContinue: {}, onSave: { _ in true }
    )
}
#Preview("Fertilizer Entry", traits: .sizeThatFitsLayout) {
    @Previewable @State var draft = FertilizerDraft(record: GardenPreviewData.fertilizers[0])
    FertilizerEntryCard(draft: $draft).padding().frame(width: 402)
}
#Preview("Panen · Default") {
    HarvestHistoryEditor(record: nil, onSave: { _ in true })
}
#endif
