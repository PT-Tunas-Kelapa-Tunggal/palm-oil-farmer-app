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
