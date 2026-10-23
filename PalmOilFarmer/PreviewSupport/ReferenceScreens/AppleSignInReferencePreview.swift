#if DEBUG
import SwiftUI

/// Reference-only rendering of the system authorization frames.
/// Actual Apple authorization must be presented by AuthenticationServices.
struct AppleSignInReferencePreview: View {
    var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: " Apple ID", onClose: {})
            if isLoading {
                Spacer()
                VStack(spacing: 24) {
                    ProgressView().controlSize(.large)
                    Text("Memverifikasi Akun").font(.body)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Selamat Datang di KROPS")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nama").foregroundStyle(.secondary).padding(.horizontal, 16)
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Deni").frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                                Divider()
                                Text("Wijaya").frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Email").foregroundStyle(.secondary).padding(.horizontal, 16)
                            VStack(spacing: 0) {
                                AppleIdentityOptionRow(title: "Bagikan email saya", subtitle: "pengguna@icloud.com", isSelected: false)
                                Divider().padding(.horizontal, 16)
                                AppleIdentityOptionRow(title: "Sembunyikan email saya",
                                                       subtitle: "Teruskan ke:\nasdjt74099483lsdjf@privaterelay.appleid.com",
                                                       isSelected: true)
                            }
                            .background(Color(uiColor: .systemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
                        }
                        PrimaryActionButton(title: "Lanjutkan", action: {})
                    }
                    .font(.body)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
        }
        .background(.background)
    }
}

struct AppleIdentityOptionRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Image(systemName: isSelected ? "checkmark.circle.fill" : "info.circle")
                .foregroundStyle(.secondary)
        }
        .padding(16)
    }
}

#Preview("Apple ID · Reference") { AppleSignInReferencePreview() }
#Preview("Apple ID · Loading Reference") { AppleSignInReferencePreview(isLoading: true) }
#Preview("Apple Email Row", traits: .sizeThatFitsLayout) {
    AppleIdentityOptionRow(title: "Bagikan email saya", subtitle: "pengguna@icloud.com", isSelected: false)
        .frame(width: 354)
}
#endif
