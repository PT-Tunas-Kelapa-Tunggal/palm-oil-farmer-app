import SwiftUI

struct GardenProfileEditorView: View {
    @State private var model: GardenProfileEditorViewModel
    let onClose: () -> Void
    @FocusState private var focusedField: GardenProfileEditorField?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(model: GardenProfileEditorViewModel, onClose: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onClose = onClose
    }

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            GardenProfileHeader(onBack: close)
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        GardenProfileSectionHeader(title: "Riwayat Panen")
                        VStack(spacing: 8) {
                            GardenProfileFieldRow(title: "Frekuensi Panen dalam Sebulan") {
                                FrequencyStepper(value: $model.harvestFrequency,
                                                        range: HarvestRecord.frequencyRange, label: "Frekuensi panen per bulan")
                            }
                            GardenProfileFieldRow(title: "Rata-rata berat hasil panen dalam sebulan") {
                                HStack(spacing: 16) {
                                    TextField("0", value: $model.monthlyWeightKg, format: .number)
                                        .font(.largeTitle.bold()).multilineTextAlignment(.center)
                                        .keyboardType(.decimalPad).focused($focusedField, equals: .monthlyHarvestWeight)
                                        .frame(minWidth: 64, idealWidth: 88, maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 88)
                                        .accessibilityLabel("Rata-rata berat panen per bulan, kilogram")
                                    Text("kg").font(.title2.bold())
                                }
                            }
                        }
                    }
                    VStack(spacing: 16) {
                        GardenProfileSectionHeader(title: "Frekuensi Pemupukan")
                        GardenProfileFieldRow(title: "Frekuensi Pemupukan dalam setahun") {
                            FrequencyStepper(value: $model.fertilizationFrequency, range: GardenProfileValidation.fertilizationFrequencyRange,
                                                    label: "Frekuensi pemupukan per tahun")
                        }
                    }
                    VStack(spacing: 16) {
                        GardenProfileSectionHeader(title: "Jenis Pupuk",
                                            message: "Data pupuk yang diaplikasikan di kebun ini dalam periode pemupukan terakhir")
                        ForEach($model.fertilizers) { $draft in
                            FertilizerInputCard(draft: $draft, focusedField: $focusedField)
                                .contextMenu {
                                    Button("Hapus jenis pupuk", role: .destructive) { model.removeFertilizer(id: draft.id) }
                                }
                                .accessibilityAction(named: "Hapus jenis pupuk") { model.removeFertilizer(id: draft.id) }
                        }
                        Button { model.addFertilizer() } label: {
                            Label("Tambah jenis pupuk", systemImage: "plus")
                                .font(.body).frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    GardenProfileActionButton(title: "Simpan") {
                        focusedField = nil
                        _ = model.save()
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(GardenProfileStyle.formBackground)
        .safeAreaInset(edge: .bottom) {
            if focusedField != nil {
                KeyboardActionBar(onNext: model.nextField(after: focusedField).map { next in { focusedField = next } },
                                  onDone: { focusedField = nil })
            }
        }
        .alert("Profil belum tersimpan", isPresented: Binding(
            get: { model.errorMessage != nil }, set: { if !$0 { model.validationIssue = nil } }
        )) { Button("Mengerti", role: .cancel) {} } message: { Text(model.errorMessage ?? "") }
        .presentationDetents([.large]).presentationDragIndicator(.hidden)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func close() {
        focusedField = nil
        onClose()
    }
}

#if DEBUG
#Preview("Form profil · Kosong") {
    GardenProfileEditorView(model: GardenProfileCanvasFixtures.makeEditor(filled: false), onClose: {})
        .environment(\.locale, Locale(identifier: "id_ID"))
}
#Preview("Form profil · NPK custom") {
    GardenProfileEditorView(model: GardenProfileCanvasFixtures.makeEditor(), onClose: {})
        .environment(\.locale, Locale(identifier: "id_ID"))
}
#endif
