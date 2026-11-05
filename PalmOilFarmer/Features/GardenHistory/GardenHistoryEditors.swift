import SwiftUI

struct FertilizerHistoryEditor: View {
    @State private var flow: FertilizerHistoryFlow
    @FocusState private var focusedField: FertilizerField?
    @Environment(\.dismiss) private var dismiss

    init(flow: FertilizerHistoryFlow) { _flow = State(initialValue: flow) }

    var body: some View {
        @Bindable var model = flow.viewModel
        @Bindable var coordinator = flow.coordinator
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(title: "Riwayat Pemupukan",
                             confirmationAction: save, onClose: coordinator.close)
                ScrollViewReader { reader in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach($model.drafts) { $draft in
                                FertilizerEntryCard(draft: $draft, focusedField: $focusedField) {
                                    focusedField = nil
                                    coordinator.selectType(for: draft.id)
                                }
                                .contextMenu {
                                    Button("Hapus jenis pupuk", role: .destructive) {
                                        model.removeDraft(id: draft.id)
                                    }
                                }
                            }
                            Button {
                                guard let id = model.addDraft() else { return }
                                focusedField = nil
                                withAnimation { reader.scrollTo(id, anchor: .top) }
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
            .navigationDestination(item: $coordinator.selectedDraftID) { id in
                SelectionListView(
                    title: "Jenis Pupuk", options: FertilizerCatalogue.names,
                    selected: model.drafts.first(where: { $0.id == id })?.name,
                    footer: "Pilih sesuai nama pupuk yang tertera pada karung. Jika tidak ada dalam daftar, pilih Lainnya."
                ) { name in
                    model.selectType(name, for: id)
                }
            }
            .alert("Riwayat belum tersimpan", isPresented: Binding(
                get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("Mengerti", role: .cancel) {}
            } message: { Text(model.errorMessage ?? "") }
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .presentationDetents([.large])
    }

    private var nextField: FertilizerField? { flow.viewModel.nextField(after: focusedField) }

    private func save() {
        focusedField = nil
        _ = flow.viewModel.save()
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
        .background(KropsTheme.cardFill, in: RoundedRectangle(cornerRadius: 24))
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
    @State private var flow: HarvestHistoryFlow
    @Environment(\.dismiss) private var dismiss
    static let frequencyRange = HarvestRecord.frequencyRange

    init(flow: HarvestHistoryFlow) { _flow = State(initialValue: flow) }

    var body: some View {
        @Bindable var model = flow.viewModel
        let coordinator = flow.coordinator
        VStack(spacing: 0) {
            ScreenHeader(title: "Riwayat Panen", confirmationAction: save, onClose: coordinator.close)
            VStack(spacing: 16) {
                HarvestCard(title: "Frekuensi Panen",
                            message: "Jumlah panen yang biasanya dilakukan di kebun ini",
                            footer: "dalam satu bulan") {
                    HarvestFrequencyStepper(value: $model.frequency, range: Self.frequencyRange)
                }
                HarvestCard(title: "Rata-rata berat per panen",
                            message: "Perkiraan berat TBS yang didapat setiap kali panen",
                            footer: "setiap kali panen") {
                    HarvestWeightWheel(selection: $model.weight, options: model.weightOptions)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .onDisappear { coordinator.close() }
        .fittedSheetHeight()
        .presentationBackground(Color(uiColor: .systemBackground))
        .alert("Riwayat belum tersimpan", isPresented: $model.showsError) {
            Button("Mengerti", role: .cancel) {}
        }
    }

    private func save() { _ = flow.viewModel.save() }
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
