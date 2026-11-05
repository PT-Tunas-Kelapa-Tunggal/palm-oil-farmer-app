import SwiftUI

struct ConsentCheckbox: View {
    @Binding var isChecked: Bool
    let message: String

    var body: some View {
        Button { isChecked.toggle() } label: {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                Text(message).font(.body)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(message)
        .accessibilityValue(isChecked ? "Disetujui" : "Belum disetujui")
    }
}

/// Program information first, then the contact form, in one sheet.
struct ReviewRequestView: View {
    @State private var flow: ReviewRequestFlow
    @Environment(\.dismiss) private var dismiss

    init(flow: ReviewRequestFlow) { _flow = State(initialValue: flow) }

    var body: some View {
        @Bindable var coordinator = flow.coordinator
        @Bindable var model = flow.viewModel
        NavigationStack(path: $coordinator.path) {
            information
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: ReviewRequestRoute.self) { route in
                    switch route {
                    case .contact(let id):
                        ReviewContactFormView(flow: flow.makeContactFlow(id))
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .presentationDetents([.large])
        .alert("Persetujuan diperlukan", isPresented: $model.showsConsentError) {
            Button("Mengerti", role: .cancel) {}
        } message: { Text("Baca informasi dan setujui program peninjauan sebelum melanjutkan.") }
    }

    private var information: some View {
        @Bindable var model = flow.viewModel
        return VStack(spacing: 0) {
            ScreenHeader(title: "Permintaan Peninjauan", onClose: flow.coordinator.close)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Setelah batas kebun selesai dipetakan, ajukan peninjauan agar petugas dapat mengambil gambar kebun menggunakan drone dan menganalisis kondisi kebunmu. Hasil peninjauan akan membantu kamu memahami kondisi kebun dan kebutuhan pemupukannya.")
                    Text("Informasi proses peninjauan").fontWeight(.semibold)
                    processStep("1. Ajukan peninjauan", message: "Kirim permintaan peninjauan untuk kebun yang sudah kamu petakan.")
                    processStep("2. Pengambilan gambar kebun", message: "Petugas akan menjadwalkan kunjungan untuk mengambil gambar kebun menggunakan drone.")
                    processStep("3. Analisis kondisi kebun", message: "Gambar kebun akan diproses untuk menghasilkan informasi mengenai kondisi kebun dan variasi kebutuhan hara.")
                    processStep("4. Lihat hasil peninjauan", message: "Setelah analisis selesai, kamu dapat melihat hasilnya untuk membantu merencanakan pemupukan.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            VStack(spacing: 16) {
                ConsentCheckbox(isChecked: $model.hasConsent,
                                message: "Saya memahami dan menyetujui program peninjauan kebun.")
                    .padding(.horizontal, 8)
                PrimaryActionButton(title: "Lanjutkan") {
                    model.continueToContact()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 2)
        }
    }

    private func processStep(_ title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).fontWeight(.semibold)
            Text(message)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Informasi Peninjauan") {
    ReviewRequestView(onSubmit: { _ in })
}
#Preview("Consent", traits: .sizeThatFitsLayout) {
    @Previewable @State var checked = false
    ConsentCheckbox(isChecked: $checked, message: "Saya memahami dan menyetujui program peninjauan kebun.")
        .padding(24).frame(width: 402)
}
