import SwiftUI

struct FertilizerHistoryScreen: View {
    @State private var drafts: [FertilizerDraft]
    @State private var selectedDraftID: UUID?
    @State private var errorMessage: String?
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
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach($drafts) { $draft in
                            FertilizerEntryCard(draft: $draft) { selectedDraftID = draft.id }
                                .contextMenu {
                                    Button("Hapus jenis pupuk", role: .destructive) {
                                        drafts.removeAll { $0.id == draft.id }
                                    }
                                }
                        }
                        Button {
                            drafts.append(FertilizerDraft())
                        } label: {
                            Label("Tambah jenis pupuk", systemImage: "plus")
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color(uiColor: .systemGray4), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .containerBackground(.clear, for: .navigation)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedDraftID) { id in
                SelectionListScreen(
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

    private func save() {
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

struct HarvestHistoryScreen: View {
    let onSave: (HarvestRecord) -> Bool
    @State private var frequency: Int
    @State private var weight: Double
    @State private var showsError = false
    @Environment(\.dismiss) private var dismiss

    init(record: HarvestRecord?, onSave: @escaping (HarvestRecord) -> Bool) {
        self.onSave = onSave
        _frequency = State(initialValue: min(max(record?.frequencyPerMonth ?? 2, 1), 31))
        _weight = State(initialValue: record?.latestWeightKg ?? 450)
    }

    private var weightOptions: [Double] {
        Array(Set(stride(from: 50.0, through: 5000.0, by: 50) + [weight])).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Riwayat Panen", confirmationAction: save, onClose: { dismiss() })
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Text("Frekuensi Panen").font(.title2.weight(.bold))
                        Text("Jumlah panen yang biasanya dilakukan\ndi kebun ini")
                            .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Stepper(value: $frequency, in: 1...31) {
                            Text("\(frequency) kali")
                                .font(.title.weight(.semibold))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        Text("dalam satu bulan").font(.body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .frame(minHeight: 254)
                    .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 48))

                    VStack(spacing: 0) {
                        Text("Rata-rata berat panen").font(.title2.weight(.bold))
                        Text("Perkiraan berat TBS yang didapat setiap\nkali panen")
                            .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Picker("Berat panen dalam kg", selection: $weight) {
                            ForEach(weightOptions, id: \.self) { value in
                                Text("\(value.formatted()) kg").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 217)
                        Text("setiap kali panen").font(.body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .frame(minHeight: 363)
                    .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 48))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.height(721), .large])
        .alert("Riwayat belum tersimpan", isPresented: $showsError) {
            Button("Mengerti", role: .cancel) {}
        }
    }

    private func save() {
        guard (1...31).contains(frequency), weight.isFinite, weight > 0 else { showsError = true; return }
        if onSave(HarvestRecord(frequencyPerMonth: frequency, latestWeightKg: weight)) {
            dismiss()
        } else { showsError = true }
    }
}

#if DEBUG
#Preview("Pemupukan · Filled", traits: .fixedLayout(width: 402, height: 918)) {
    FertilizerHistoryScreen(
        records: [FertilizerRecord(name: "Dolomit Super", bagWeightKg: 50, bagCount: 6, doseKgPerTree: 1.5)],
        includesEmptyDraft: true, onSave: { _ in true }
    )
}
#Preview("Fertilizer Entry", traits: .sizeThatFitsLayout) {
    @Previewable @State var draft = FertilizerDraft(record: GardenPreviewData.fertilizers[0])
    FertilizerEntryCard(draft: $draft, onSelectType: {}).padding().frame(width: 402)
}
#Preview("Panen · Default", traits: .fixedLayout(width: 402, height: 721)) {
    HarvestHistoryScreen(record: nil, onSave: { _ in true })
}
#endif
