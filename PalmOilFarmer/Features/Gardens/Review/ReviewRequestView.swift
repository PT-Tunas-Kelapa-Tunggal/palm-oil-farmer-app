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
    let onSubmit: (ReviewContactDetails) async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showsForm = false

    var body: some View {
        NavigationStack {
            information
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showsForm) {
                    ReviewContactFormView(onSubmit: onSubmit)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(GardenFlowStyle.background)
    }

    private var information: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Peninjauan Kebun", systemImage: "chevron.left", onClose: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    processStep("Kenali kebutuhan setiap bagian kebun", symbol: "leaf.fill",
                                message: "Petugas memeriksa kondisi tanaman di seluruh kebun Anda. Dari pemeriksaan ini, Anda dapat mengetahui bagian kebun yang sehat dan bagian yang perlu diperhatikan.")
                    processStep("Pengambilan gambar dengan drone", symbol: "camera.fill",
                                message: "Petugas datang sesuai jadwal yang disepakati dan mengambil gambar kebun dari udara. Gambar tersebut diolah untuk melihat tingkat kehijauan daun di setiap area.")
                    processStep("Rekomendasi pupuk per area", symbol: "chart.xyaxis.line",
                                message: "Anda akan menerima peta kondisi kebun beserta dosis pupuk yang sesuai untuk setiap area. Pemupukan menjadi lebih tepat sehingga pupuk tidak terbuang.")
                    GardenFlowActionButton(title: "Ajukan Sekarang") { showsForm = true }
                        .padding(.top, 12)
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
        }
        .background(GardenFlowStyle.background)
    }

    private func processStep(_ title: String, symbol: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                if symbol == "camera.fill" {
                    Image("CodedUI3ReviewDrone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 167, height: 140)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 84, weight: .semibold))
                }
            }
                .frame(maxWidth: .infinity, minHeight: 157)
                .background(Color(uiColor: .systemGray5), in: RoundedRectangle(cornerRadius: 20))
                .accessibilityHidden(true)
            Text(title).font(.headline)
            Text(message).fixedSize(horizontal: false, vertical: true)
        }
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
