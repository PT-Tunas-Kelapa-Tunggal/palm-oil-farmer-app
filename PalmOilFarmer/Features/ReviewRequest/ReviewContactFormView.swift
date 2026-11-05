import SwiftUI

struct ReviewContactFormView: View {
    @State private var flow: ReviewContactFlow
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: ReviewContactField?
    private typealias Field = ReviewContactField

    init(flow: ReviewContactFlow) { _flow = State(initialValue: flow) }

    var body: some View {
        @Bindable var model = flow.viewModel
        VStack(spacing: 0) {
            ScreenHeader(title: "Permintaan Peninjauan", onClose: {
                flow.close()
                if flow.dismissOnClose { dismiss() }
            })
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Isi data di bawah ini agar petugas dapat menghubungi Anda dan menjadwalkan kunjungan ke kebun.")
                            .font(.body)
                        VStack(spacing: 16) {
                            contactField("Nama", id: .name) {
                                TextField("Masukkan Nama Lengkap", text: $model.name)
                                    .textContentType(.name)
                                    .textInputAutocapitalization(.words)
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .phone }
                            }
                            contactField("Nomor Telepon", id: .phone) {
                                TextField("cth: 085048384438", text: $model.phone)
                                    .textContentType(.telephoneNumber).keyboardType(.phonePad)
                                    .focused($focusedField, equals: .phone)
                            }
                            contactField("Alamat Rumah", id: .address) {
                                TextField("Contoh: Dusun Sido Mulyo RT 02/RW 01, Desa Pangkalan Lesung, Kec. Pangkalan Lesung",
                                          text: $model.address, axis: .vertical)
                                    .textContentType(.fullStreetAddress)
                                    .lineLimit(3...5)
                                    .focused($focusedField, equals: .address)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                // Room to scroll the last field clear of the keyboard buttons.
                .contentMargins(.bottom, 96, for: .scrollContent)
                .scrollDismissesKeyboard(.immediately)
                .onChange(of: focusedField) { _, field in
                    guard let field else { return }
                    withAnimation { reader.scrollTo(field, anchor: .center) }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let focusedField {
                    KeyboardActionBar(onNext: focusedField.next.map { next in { self.focusedField = next } },
                                      onDone: { self.focusedField = nil })
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: focusedField == nil)
            .bottomActionBar {
                VStack(spacing: 16) {
                    ConsentCheckbox(isChecked: $model.hasConsent,
                                    message: "Saya memastikan nomor telepon dan alamat di atas sudah benar.")
                        .padding(.horizontal, 8)
                    PrimaryActionButton(title: model.isSubmitting ? "Mengirim…" : "Ajukan Sekarang",
                                        systemImage: "paperplane.fill", imagePlacement: .trailing) {
                        Task {
                            focusedField = nil
                            await model.submit()
                        }
                    }
                    .disabled(model.isSubmitting)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 2)
            }
        }
        .alert("Pengajuan belum dikirim", isPresented: Binding(
            get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("Mengerti", role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }

    private func contactField<Content: View>(_ title: String, id: Field,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title).font(.headline)
            content().font(.body)
            Divider()
        }
        .id(id)
    }
}

#Preview("Formulir Peninjauan · Empty") {
    ReviewContactFormView(onSubmit: { _ in throw ReviewServiceError.unavailable })
}
