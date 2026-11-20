import SwiftUI

/// "Profil Kebun" form page (pushed): harvest and fertilizer history.
struct GardenProfileEditorView: View {
    @State private var viewModel: GardenProfileEditorViewModel
    let onClose: () -> Void
    @FocusState private var focusedField: GardenProfileEditorField?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: GardenProfileEditorViewModel, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onClose = onClose
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            GardenProfileHeader(onBack: close)
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        GardenProfileSectionHeader(title: "Riwayat Panen")
                        VStack(spacing: 0) {
                            GardenProfileFieldRow(title: "Frekuensi panen", message: "Berapa kali panen dalam sebulan") {
                                FrequencyStepper(value: $viewModel.harvestFrequency,
                                                        range: HarvestRecord.frequencyRange, label: "Frekuensi panen per bulan")
                            }
                            Divider()
                            GardenProfileFieldRow(title: "Rata-rata hasil panen", message: "Total berat buah dalam\nsebulan", minimumHeight: 88) {
                                HStack(spacing: 6) {
                                    TextField("0", value: $viewModel.monthlyWeightKg, format: .number)
                                        .font(.title3.weight(.semibold)).multilineTextAlignment(.center)
                                        .keyboardType(.decimalPad).focused($focusedField, equals: .monthlyHarvestWeight)
                                        .frame(minWidth: 48, idealWidth: 64, maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 64)
                                        .accessibilityLabel("Rata-rata berat panen per bulan, kilogram")
                                    Text("kg").font(.body).foregroundStyle(.secondary)
                                }.padding(10).background(KropsTheme.surfaceCardRaised, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }.padding(.horizontal, 16).background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(KropsTheme.surfaceCard)
                                .onTapGesture { focusedField = nil }
                        }
                    }
                    VStack(spacing: 8) {
                        GardenProfileSectionHeader(title: "Riwayat Pemupukan")
                        GardenProfileFieldRow(title: "Frekuensi pemupukan", message: "Berapa kali memupuk dalam setahun") {
                            FrequencyStepper(value: $viewModel.fertilizationFrequency, range: GardenProfileValidation.fertilizationFrequencyRange,
                                                    label: "Frekuensi pemupukan per tahun")
                        }.padding(.horizontal, 16).background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(KropsTheme.surfaceCard)
                                .onTapGesture { focusedField = nil }
                        }
                    }
                    VStack(spacing: 8) {
                        GardenProfileSectionHeader(title: "Jenis Pupuk",
                                            message: "Pupuk yang diberikan pada pemupukan terakhir.")
                        ForEach($viewModel.fertilizers) { $draft in
                            FertilizerInputCard(
                                draft: $draft,
                                focusedField: $focusedField,
                                showsDeleteButton: viewModel.fertilizers.count > 1 || !draft.isEmpty,
                                onDelete: {
                                    focusedField = nil
                                    viewModel.removeFertilizer(id: draft.id)
                                }
                            )
                                .contextMenu {
                                    Button("Hapus jenis pupuk", role: .destructive) { viewModel.removeFertilizer(id: draft.id) }
                                }
                                .accessibilityAction(named: "Hapus jenis pupuk") { viewModel.removeFertilizer(id: draft.id) }
                        }
                        Button { viewModel.addFertilizer() } label: {
                            Label("Tambah jenis pupuk", systemImage: "plus")
                                .font(.body).frame(maxWidth: .infinity, minHeight: 52)
                                .foregroundStyle(KropsTheme.accentPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                    GardenProfileActionButton(title: "Simpan Profil Kebun") {
                        focusedField = nil
                        _ = viewModel.save()
                    }
                }
                .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 34)
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = nil }
                }
            }
            .scrollBounceBehavior(.always)
            .scrollDismissesKeyboard(.immediately)
            .background {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { focusedField = nil }
            }
        }
        .background {
            KropsTheme.surfaceBackground
                .ignoresSafeArea()
                .onTapGesture { focusedField = nil }
        }
        .alert("Profil belum tersimpan", isPresented: Binding(
            get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.validationIssue = nil } }
        )) { Button("Mengerti", role: .cancel) {} } message: { Text(viewModel.errorMessage ?? "") }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func close() {
        focusedField = nil
        onClose()
    }
}

#if DEBUG
#Preview("Form profil · Kosong") {
    GardenProfileEditorView(viewModel: GardenProfileCanvasFixtures.makeEditor(filled: false), onClose: {})
        .environment(\.locale, Locale(identifier: "id_ID"))
}
#Preview("Form profil · NPK custom") {
    GardenProfileEditorView(viewModel: GardenProfileCanvasFixtures.makeEditor(), onClose: {})
        .environment(\.locale, Locale(identifier: "id_ID"))
}
#Preview("Form profil · Dalam navigasi") {
    NavigationStack {
        GardenProfileEditorView(viewModel: GardenProfileCanvasFixtures.makeEditor(), onClose: {})
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#Preview("Form profil · Teks besar") {
    NavigationStack {
        GardenProfileEditorView(viewModel: GardenProfileCanvasFixtures.makeEditor(filled: false), onClose: {})
            .environment(\.dynamicTypeSize, .accessibility3)
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#endif
