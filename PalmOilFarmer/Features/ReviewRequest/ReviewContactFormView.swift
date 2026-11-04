import SwiftUI

struct ReviewContactFormView: View {
    var onClose: (() -> Void)? = nil
    let onSubmit: (ReviewContactDetails) async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var hasConsent = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field: CaseIterable {
        case name, phone, address

        var next: Field? {
            let all = Self.allCases
            guard let index = all.firstIndex(of: self), index + 1 < all.count else { return nil }
            return all[index + 1]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Permintaan Peninjauan", onClose: { (onClose ?? { dismiss() })() })
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Isi data di bawah ini agar petugas dapat menghubungi Anda dan menjadwalkan kunjungan ke kebun.")
                            .font(.body)
                        VStack(spacing: 16) {
                            contactField("Nama", id: .name) {
                                TextField("Masukkan Nama Lengkap", text: $name)
                                    .textContentType(.name)
                                    .textInputAutocapitalization(.words)
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .phone }
                            }
                            contactField("Nomor Telepon", id: .phone) {
                                TextField("cth: 085048384438", text: $phone)
                                    .textContentType(.telephoneNumber).keyboardType(.phonePad)
                                    .focused($focusedField, equals: .phone)
                            }
                            contactField("Alamat Rumah", id: .address) {
                                TextField("Contoh: Dusun Sido Mulyo RT 02/RW 01, Desa Pangkalan Lesung, Kec. Pangkalan Lesung",
                                          text: self.$address, axis: .vertical)
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
                    ConsentCheckbox(isChecked: $hasConsent,
                                    message: "Saya memastikan nomor telepon dan alamat di atas sudah benar.")
                        .padding(.horizontal, 8)
                    PrimaryActionButton(title: isSubmitting ? "Mengirim…" : "Ajukan Sekarang",
                                        systemImage: "paperplane.fill", imagePlacement: .trailing) {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 2)
            }
        }
        .alert("Pengajuan belum dikirim", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Mengerti", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
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

    @MainActor
    private func submit() async {
        guard !isSubmitting else { return }
        focusedField = nil
        guard let contact = ReviewContactDetails.validated(
            name: name, phone: phone, address: address, hasConfirmedContact: hasConsent
        ) else {
            errorMessage = "Lengkapi nama, nomor telepon, alamat rumah, dan persetujuan terlebih dahulu."
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await onSubmit(contact)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Formulir Peninjauan · Empty") {
    ReviewContactFormView(onSubmit: { _ in throw ReviewServiceError.unavailable })
}
