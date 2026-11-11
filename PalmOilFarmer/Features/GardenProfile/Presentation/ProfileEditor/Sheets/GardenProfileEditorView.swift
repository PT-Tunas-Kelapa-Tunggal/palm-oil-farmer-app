import SwiftUI

/// SHEET "Lengkapi / Ubah Profil": harvest + fertilizer form (`FertilizerInputCard` per fertilizer).
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
        DynamicSheet(animation: .bouncy, size: .large) {
            sheetContent
        }
        .presentationBackgroundInteraction(.disabled)
        .presentationDragIndicator(.hidden)
        .presentationContentInteraction(.scrolls)
    }

    @ViewBuilder
    private var sheetContent: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            GardenProfileHeader(onBack: close)
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        GardenProfileSectionHeader(title: "Riwayat Panen")
                        VStack(spacing: 0) {
                            GardenProfileFieldRow(title: "Frekuensi panen", message: "Berapa kali panen dalam sebulan") {
                                FrequencyStepper(value: $model.harvestFrequency,
                                                        range: HarvestRecord.frequencyRange, label: "Frekuensi panen per bulan")
                            }
                            Divider()
                            GardenProfileFieldRow(title: "Rata-rata hasil panen", message: "Total berat buah dalam\nsebulan", minimumHeight: 88) {
                                HStack(spacing: 6) {
                                    TextField("0", value: $model.monthlyWeightKg, format: .number)
                                        .font(.title3.weight(.semibold)).multilineTextAlignment(.center)
                                        .keyboardType(.decimalPad).focused($focusedField, equals: .monthlyHarvestWeight)
                                        .frame(minWidth: 48, idealWidth: 64, maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 64)
                                        .accessibilityLabel("Rata-rata berat panen per bulan, kilogram")
                                    Text("kg").font(.body).foregroundStyle(.secondary)
                                }.padding(10).background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }.padding(.horizontal, 16).background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(GardenProfileStyle.card)
                                .onTapGesture { focusedField = nil }
                        }
                    }
                    VStack(spacing: 8) {
                        GardenProfileSectionHeader(title: "Riwayat Pemupukan")
                        GardenProfileFieldRow(title: "Frekuensi pemupukan", message: "Berapa kali memupuk dalam setahun") {
                            FrequencyStepper(value: $model.fertilizationFrequency, range: GardenProfileValidation.fertilizationFrequencyRange,
                                                    label: "Frekuensi pemupukan per tahun")
                        }.padding(.horizontal, 16).background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(GardenProfileStyle.card)
                                .onTapGesture { focusedField = nil }
                        }
                    }
                    VStack(spacing: 8) {
                        GardenProfileSectionHeader(title: "Jenis Pupuk",
                                            message: "Pupuk yang diberikan pada pemupukan terakhir.")
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
                                .foregroundStyle(GardenProfileStyle.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    GardenProfileActionButton(title: "Simpan Profil Kebun") {
                        focusedField = nil
                        _ = model.save()
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
            GardenProfileStyle.formBackground
                .ignoresSafeArea()
                .onTapGesture { focusedField = nil }
        }
        .alert("Profil belum tersimpan", isPresented: Binding(
            get: { model.errorMessage != nil }, set: { if !$0 { model.validationIssue = nil } }
        )) { Button("Mengerti", role: .cancel) {} } message: { Text(model.errorMessage ?? "") }
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
#Preview("Sheet Ubah Profil") {
    SheetPreview(backdrop: "ProfileHiFiMap") {
        GardenProfileEditorView(model: GardenProfileCanvasFixtures.makeEditor(), onClose: {})
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#Preview("Sheet Ubah Profil · Teks besar") {
    SheetPreview(backdrop: "ProfileHiFiMap") {
        GardenProfileEditorView(model: GardenProfileCanvasFixtures.makeEditor(filled: false), onClose: {})
            .environment(\.dynamicTypeSize, .accessibility3)
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#endif
