import SwiftUI

/// A numeric field in one fertilizer card; used for focus and scrolling.
struct FertilizerField: Hashable {
    enum Kind: CaseIterable { case bagWeight, bagCount, dose }
    let draftID: UUID
    let kind: Kind
}

struct FertilizerHistoryEditor: View {
    @State private var drafts: [FertilizerDraft]
    @State private var selectedDraftID: UUID?
    @State private var errorMessage: String?
    @FocusState private var focusedField: FertilizerField?
    let onSave: ([FertilizerRecord]) -> Bool
    @Environment(\.dismiss) private var dismiss

    init(records: [FertilizerRecord], includesEmptyDraft: Bool = false,
         onSave: @escaping ([FertilizerRecord]) -> Bool) {
        var drafts = records.map { FertilizerDraft(record: $0) }
        if drafts.isEmpty || includesEmptyDraft { drafts.append(FertilizerDraft()) }
        _drafts = State(initialValue: drafts)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(title: "Riwayat Pemupukan", buttonSize: 44, height: 68,
                             confirmationAction: save, onClose: { dismiss() })
                ScrollViewReader { reader in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach($drafts) { $draft in
                                FertilizerEntryCard(draft: $draft, focusedField: $focusedField) {
                                    focusedField = nil
                                    selectedDraftID = draft.id
                                }
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
            .navigationDestination(item: $selectedDraftID) { id in
                SelectionListView(
                    title: "Jenis Pupuk", options: FertilizerCatalogue.names,
                    selected: drafts.first(where: { $0.id == id })?.name,
                    footer: "Pilih sesuai nama pupuk yang tertera pada karung. Jika tidak ada dalam daftar, pilih Lainnya."
                ) { name in
                    guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
                    drafts[index].name = name
                }
            }
            .alert("Riwayat belum tersimpan", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Mengerti", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
        }
        .presentationDetents([.large])
    }

    private var nextField: FertilizerField? {
        let order = drafts.flatMap { draft in FertilizerField.Kind.allCases.map { FertilizerField(draftID: draft.id, kind: $0) } }
        guard let focusedField, let index = order.firstIndex(of: focusedField), index + 1 < order.count else { return nil }
        return order[index + 1]
    }

    private func save() {
        focusedField = nil
        let filled = drafts.filter { !$0.isEmpty }
        let records = filled.compactMap(\.record)
        guard records.count == filled.count else {
            errorMessage = "Lengkapi jenis pupuk, berat, jumlah karung, dan dosis dengan nilai lebih dari nol."
            return
        }
        if onSave(records) { dismiss() } else {
            errorMessage = "Data tidak dapat disimpan di perangkat. Coba lagi."
        }
    }
}

struct KeyboardActionBar: View {
    var onNext: (() -> Void)?
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            if let onNext {
                Button(action: onNext) {
                    Label("Berikutnya", systemImage: "chevron.down")
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.glass)
            }
            Button(action: onDone) {
                Text("Selesai").fontWeight(.semibold).padding(.horizontal, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(KropsTheme.buttonBackground)
        }
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        // Fades the content scrolling underneath, like the system scroll edge effect.
        .background {
            LinearGradient(stops: [.init(color: Color(uiColor: .systemBackground).opacity(0), location: 0),
                                   .init(color: Color(uiColor: .systemBackground), location: 0.45)],
                           startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)
        }
    }
}

struct FertilizerEntryCard: View {
    @Binding var draft: FertilizerDraft
    var focusedField: FocusState<FertilizerField?>.Binding? = nil
    let onSelectType: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FormSelectionRow(
                title: "Jenis Pupuk", placeholder: "Pilih jenis pupuk",
                value: draft.name.isEmpty ? nil : draft.name, action: onSelectType
            )
            .id(draft.id)
            Divider()
            numberField("Berat per karung", unit: "kg", kind: .bagWeight,
                        accessibility: "Berat per karung, kilogram") {
                TextField("cth: 50", value: $draft.bagWeightKg, format: .number).keyboardType(.decimalPad)
            }
            Divider()
            numberField("Jumlah karung", unit: "sak", kind: .bagCount,
                        accessibility: "Jumlah karung") {
                TextField("cth: 6", value: $draft.bagCount, format: .number).keyboardType(.numberPad)
            }
            Divider()
            numberField("Dosis per pohon", unit: "kg", kind: .dose,
                        accessibility: "Dosis per pohon, kilogram") {
                TextField("cth: 1.5", value: $draft.doseKgPerTree, format: .number).keyboardType(.decimalPad)
            }
        }
        .font(.title3.weight(.semibold))
        .padding(16)
        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 24))
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
    @State private var frequency: Int
    @State private var weight: Double
    @State private var showsError = false
    @Environment(\.dismiss) private var dismiss

    static let frequencyRange = 1...31

    init(record: HarvestRecord?, onSave: @escaping (HarvestRecord) -> Bool) {
        self.onSave = onSave
        _frequency = State(initialValue: min(max(record?.frequencyPerMonth ?? 2, Self.frequencyRange.lowerBound),
                                             Self.frequencyRange.upperBound))
        _weight = State(initialValue: record?.latestWeightKg ?? 450)
    }

    private var weightOptions: [Double] {
        Array(Set(stride(from: 50.0, through: 5000.0, by: 50) + [weight])).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Riwayat Panen", confirmationAction: save, onClose: { dismiss() })
            VStack(spacing: 16) {
                HarvestCard(title: "Frekuensi Panen",
                            message: "Jumlah panen yang biasanya dilakukan di kebun ini",
                            footer: "dalam satu bulan") {
                    HarvestFrequencyStepper(value: $frequency, range: Self.frequencyRange)
                }
                HarvestCard(title: "Rata-rata berat per panen",
                            message: "Perkiraan berat TBS yang didapat setiap kali panen",
                            footer: "setiap kali panen") {
                    HarvestWeightWheel(selection: $weight, options: weightOptions)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .fittedSheetHeight()
        .presentationBackground(Color(uiColor: .systemBackground))
        .alert("Riwayat belum tersimpan", isPresented: $showsError) {
            Button("Mengerti", role: .cancel) {}
        }
    }

    private func save() {
        guard Self.frequencyRange.contains(frequency), weight.isFinite, weight > 0 else { showsError = true; return }
        if onSave(HarvestRecord(frequencyPerMonth: frequency, latestWeightKg: weight)) {
            dismiss()
        } else { showsError = true }
    }
}

/// A rounded card with a centred title, explanation, control, and unit line, as in the Sketch form.
private struct HarvestCard<Control: View>: View {
    let title: String
    let message: String
    let footer: String
    @ViewBuilder let control: () -> Control

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                Text(title).font(.title2.bold())
                Text(message).font(.body).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            control()
            Text(footer).font(.body)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(uiColor: .quaternarySystemFill), in: RoundedRectangle(cornerRadius: 40))
    }
}

struct HarvestFrequencyStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 24) {
            stepButton("minus", label: "Kurangi", isEnabled: value > range.lowerBound) { value -= 1 }
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(value)")
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(value)))
                    Text("kali").font(.headline)
                }
                Rectangle().fill(.separator).frame(width: 57, height: 1)
            }
            .frame(minWidth: 57)
            stepButton("plus", label: "Tambah", isEnabled: value < range.upperBound) { value += 1 }
        }
        .frame(minHeight: 64)
        .animation(.snappy, value: value)
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Frekuensi panen")
        .accessibilityValue("\(value) kali dalam satu bulan")
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
                .font(.system(size: 30, weight: .regular))
                .frame(width: 44, height: 64)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.4))
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

/// Five visible rows: the centred value is large inside a capsule; rows fade with distance.
struct HarvestWeightWheel: View {
    @Binding var selection: Double
    let options: [Double]
    @State private var centred: Double?

    private static let rowHeight: CGFloat = 35

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    row(option)
                        .frame(height: Self.rowHeight)
                        .id(option)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $centred, anchor: .center)
        .contentMargins(.vertical, Self.rowHeight * 2, for: .scrollContent)
        .frame(width: 140, height: Self.rowHeight * 5)
        .background {
            Capsule()
                .fill(Color(uiColor: .quaternarySystemFill))
                .frame(width: 83, height: 41)
        }
        .overlay {
            Text("kg")
                .font(.headline)
                .offset(x: 58)
                .allowsHitTesting(false)
        }
        .onAppear { centred = selection }
        .onChange(of: centred) { _, value in
            if let value { selection = value }
        }
        .sensoryFeedback(.selection, trigger: centred)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rata-rata berat per panen")
        .accessibilityValue("\(selection.formatted()) kilogram")
        .accessibilityAdjustableAction { direction in
            guard let index = options.firstIndex(of: selection) else { return }
            let next = direction == .increment ? index + 1 : index - 1
            if options.indices.contains(next) { centred = options[next] }
        }
    }

    private func row(_ option: Double) -> some View {
        let distance = abs((options.firstIndex(of: option) ?? 0) - (options.firstIndex(of: centred ?? selection) ?? 0))
        return Text(option.formatted())
            .font(distance == 0 ? .largeTitle.bold() : distance == 1 ? .title2.bold() : .headline)
            .monospacedDigit()
            .foregroundStyle(Color.primary.opacity(distance == 0 ? 1 : distance == 1 ? 0.6 : 0.3))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { centred = option } }
    }
}

#if DEBUG
#Preview("Pemupukan · Filled", traits: .fixedLayout(width: 402, height: 918)) {
    FertilizerHistoryEditor(
        records: [FertilizerRecord(name: "Dolomit Super", bagWeightKg: 50, bagCount: 6, doseKgPerTree: 1.5)],
        includesEmptyDraft: true, onSave: { _ in true }
    )
}
#Preview("Fertilizer Entry", traits: .sizeThatFitsLayout) {
    @Previewable @State var draft = FertilizerDraft(record: GardenPreviewData.fertilizers[0])
    FertilizerEntryCard(draft: $draft, onSelectType: {}).padding().frame(width: 402)
}
#Preview("Panen · Default") {
    Color.clear.sheet(isPresented: .constant(true)) {
        HarvestHistoryEditor(record: nil, onSave: { _ in true })
    }
}
#endif
