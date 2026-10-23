#if DEBUG
import SwiftUI

/// Debug-only tools for running repeat user-testing sessions on one device.
struct DeveloperModeView: View {
    let gardenCount: Int
    let draftCount: Int
    let onEraseAll: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmsErase = false
    @AppStorage(DeveloperSettings.showsHomeFilterKey) private var showsHomeFilter = true

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Mode Developer", systemImage: "chevron.left", onClose: { dismiss() })
            List {
                Section {
                    LabeledContent("Kebun tersimpan", value: gardenCount.formatted())
                    LabeledContent("Draf", value: draftCount.formatted())
                } header: {
                    Text("Data di perangkat ini")
                }
                Section {
                    Toggle("Filter Semua / Draf / Peninjauan", isOn: $showsHomeFilter)
                        .tint(KropsTheme.primary)
                } header: {
                    Text("Tampilan beranda")
                } footer: {
                    Text("Jika dimatikan, tab filter disembunyikan dan daftar menampilkan semua kebun.")
                }
                Section {
                    Button(role: .destructive) {
                        confirmsErase = true
                    } label: {
                        Label {
                            Text("Hapus semua data kebun")
                        } icon: {
                            Image(systemName: "trash").foregroundStyle(.red)
                        }
                    }
                    .disabled(gardenCount == 0 && draftCount == 0)
                } footer: {
                    Text("Menghapus semua kebun, draf, riwayat pupuk dan panen, serta status peninjauan. Izin lokasi dan foto tidak ikut direset.")
                }
                Section {
                    Text("Tekan lama judul \"Status Pengajuan\" selama 1,5 detik untuk memajukan peninjauan ke tahap berikutnya.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Simulasi peninjauan")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Hapus semua data kebun?", isPresented: $confirmsErase, titleVisibility: .visible) {
            Button("Hapus semua", role: .destructive) {
                onEraseAll()
                dismiss()
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Tindakan ini tidak dapat dibatalkan.")
        }
    }
}

#Preview("Mode Developer") {
    NavigationStack {
        DeveloperModeView(gardenCount: 3, draftCount: 1, onEraseAll: {})
    }
}
#endif
