import SwiftUI

struct ReviewContactFormView: View {
    let onSubmit: (ReviewContactDetails) async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var hasConsent = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Permintaan Peninjauan", onClose: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Isi data di bawah ini agar petugas dapat menghubungi Anda dan menjadwalkan kunjungan ke kebun.")
                        .font(.body)
                    VStack(spacing: 16) {
                        contactField("Nama") {
                            TextField("Masukkan Nama Lengkap", text: $name)
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                        }
                        contactField("Nomor Telepon") {
                            TextField("cth: 085048384438", text: $phone)
                                .textContentType(.telephoneNumber).keyboardType(.phonePad)
                        }
                        contactField("Alamat Rumah") {
                            TextField("Contoh: Dusun Sido Mulyo RT 02/RW 01, Desa Pangkalan Lesung, Kec. Pangkalan Lesung",
                                      text: $address, axis: .vertical)
                                .textContentType(.fullStreetAddress)
                                .lineLimit(3...5)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
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
        .presentationDetents([.large])
        .alert("Pengajuan belum dikirim", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Mengerti", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    private func contactField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title).font(.headline)
            content().font(.body)
            Divider()
        }
    }

    @MainActor
    private func submit() async {
        guard !isSubmitting else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = phone.filter(\.isNumber)
        guard !trimmedName.isEmpty, !trimmedAddress.isEmpty, digits.count >= 8, hasConsent else {
            errorMessage = "Lengkapi nama, nomor telepon, alamat rumah, dan persetujuan terlebih dahulu."
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await onSubmit(ReviewContactDetails(name: trimmedName, phone: phone, address: trimmedAddress))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Formulir Peninjauan · Empty") {
    ReviewContactFormView(onSubmit: { _ in throw ReviewServiceError.unavailable })
}
